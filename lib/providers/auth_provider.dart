import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/organizacion.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserModel? _currentUser;
  Organizacion? _currentOrg;
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  AuthProvider({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _init();
  }

  UserModel? get currentUser => _currentUser;
  Organizacion? get currentOrg => _currentOrg;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _initialized;

  bool get esAdmin => _currentUser?.esAdmin ?? false;
  bool get esVendedor => _currentUser?.esVendedor ?? false;
  bool get esSuperAdmin => _currentUser?.esSuperAdmin ?? false;
  bool get puedeGestionarPagos => _currentUser?.puedeGestionarPagos ?? false;
  bool get puedeEliminar => _currentUser?.puedeEliminar ?? false;
  bool get puedeCrearRifas => _currentUser?.puedeCrearRifas ?? false;
  String? get organizacionId => _currentUser?.organizacionId;

  void _init() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      _isLoading = true;
      notifyListeners();

      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _currentUser = null;
        _currentOrg = null;
      }

      _isLoading = false;
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
        if (_currentUser!.organizacionId != null) {
          await _loadOrgData(_currentUser!.organizacionId!);
        }
      } else {
        _currentUser = null;
        _currentOrg = null;
      }
    } catch (e) {
      debugPrint('[AUTH] Error loading user data: $e');
      _currentUser = null;
      _currentOrg = null;
    }
  }

  Future<void> _loadOrgData(String orgId) async {
    try {
      final doc = await _firestore.collection('organizaciones').doc(orgId).get();
      if (doc.exists) {
        _currentOrg = Organizacion.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('[AUTH] Error loading org data: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<(String? error, UserModel? user)> register({
    required String nombre,
    required String email,
    required String password,
    required String orgNombre,
    String? orgTelefono,
    String? orgEmail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final orgId = _firestore.collection('organizaciones').doc().id;
      final org = Organizacion(
        id: orgId,
        nombre: orgNombre,
        telefono: orgTelefono,
        email: orgEmail,
        fechaCreacion: DateTime.now(),
        creadoPor: uid,
      );
          await _firestore.collection('organizaciones').doc(orgId).set(org.toMap());
          await _migrateExistingData(orgId, uid);

      final user = UserModel(
        uid: uid,
        email: email,
        nombre: nombre,
        rol: UserRol.orgAdmin,
        organizacionId: orgId,
        fechaCreacion: DateTime.now(),
        ultimoAcceso: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());

      _currentUser = user;
      _currentOrg = org;
      _isLoading = false;
      notifyListeners();

      return (null, user);
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _isLoading = false;
      notifyListeners();
      return (_error, null);
    } catch (e) {
      _error = 'Error al crear la cuenta. Intenta de nuevo.';
      _isLoading = false;
      notifyListeners();
      return (_error, null);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _currentOrg = null;
    notifyListeners();
  }

  Future<bool> checkAnyUserExists() async {
    try {
      final snapshot = await _firestore.collection('users').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return true;
    }
  }

  Future<bool> createVendedor({
    required String nombre,
    required String email,
    required String password,
  }) async {
    if (_currentUser?.organizacionId == null) return false;

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final vendedor = UserModel(
        uid: uid,
        email: email,
        nombre: nombre,
        rol: UserRol.vendedor,
        organizacionId: _currentUser!.organizacionId,
        fechaCreacion: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(vendedor.toMap());
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error creating vendedor: $e');
      return false;
    }
  }

  Future<List<UserModel>> getUsersInOrg(String orgId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('organizacionId', isEqualTo: orgId)
          .get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[AUTH] Error fetching users: $e');
      return [];
    }
  }

  Future<void> toggleUserActive(String uid, bool active) async {
    try {
      await _firestore.collection('users').doc(uid).update({'activo': active});
    } catch (e) {
      debugPrint('[AUTH] Error toggling user: $e');
    }
  }

  Future<void> updateOrgConfig(Organizacion org) async {
    try {
      await _firestore.collection('organizaciones').doc(org.id).update(org.toMap());
      _currentOrg = org;
      notifyListeners();
    } catch (e) {
      debugPrint('[AUTH] Error updating org: $e');
      rethrow;
    }
  }

  Future<void> _migrateExistingData(String orgId, String uid) async {
    try {
      int count = 0;
      final batch = _firestore.batch();

      final allRifas = await _firestore.collection('rifas').get();
      for (final doc in allRifas.docs) {
        if (!doc.data().containsKey('organizacionId') || doc.data()['organizacionId'] == null) {
          batch.update(doc.reference, {
            'organizacionId': orgId,
            'creadoPor': uid,
          });
          count++;
        }
      }

      final allParticipantes = await _firestore.collection('participantes').get();
      for (final doc in allParticipantes.docs) {
        if (!doc.data().containsKey('organizacionId') || doc.data()['organizacionId'] == null) {
          batch.update(doc.reference, {
            'organizacionId': orgId,
            'creadoPor': uid,
          });
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint('[MIGRATION] $count documentos asignados a la organización $orgId');
      }
    } catch (e) {
      debugPrint('[MIGRATION] Error: $e');
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No hay cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Credenciales inválidas.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada. Contacta al administrador.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error al iniciar sesión. Intenta de nuevo.';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
