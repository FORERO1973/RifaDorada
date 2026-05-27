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
        if (_currentUser == null) {
          _error = '⚠️ Sesión no válida. Por favor inicia sesión de nuevo.';
        }
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
          final orgDoc = await _firestore.collection('organizaciones').doc(_currentUser!.organizacionId!).get();
          if (orgDoc.exists) {
            final orgData = orgDoc.data()!;
            if (orgData['activa'] == false) {
              _currentUser = null;
              _currentOrg = null;
              _error = '⚠️ Organización suspendida. Contacta al administrador.';
              notifyListeners();
              return;
            }
            _currentOrg = Organizacion.fromMap(orgData, orgDoc.id);
          }
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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await _loadUserData(cred.user!.uid);
        if (_currentUser == null) {
          await _auth.signOut();
          _error = '⚠️ Usuario no encontrado en la base de datos. Contacta al administrador.';
        }
      }
      _isLoading = false;
      notifyListeners();
      return _currentUser != null;
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
    String? orgNombre,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final superSnapshot = await _firestore
          .collection('users')
          .where('rol', isEqualTo: 'superAdmin')
          .limit(1)
          .get();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      UserModel user;
      if (superSnapshot.docs.isEmpty) {
        user = UserModel(
          uid: uid,
          email: email,
          nombre: nombre,
          rol: UserRol.superAdmin,
          fechaCreacion: DateTime.now(),
          ultimoAcceso: DateTime.now(),
        );
      } else {
        final orgId = _firestore.collection('organizaciones').doc().id;
        final org = Organizacion(
          id: orgId,
          nombre: orgNombre ?? 'Nueva Organización',
          fechaCreacion: DateTime.now(),
          creadoPor: uid,
        );
        await _firestore.collection('organizaciones').doc(orgId).set(org.toMap());

        user = UserModel(
          uid: uid,
          email: email,
          nombre: nombre,
          rol: UserRol.orgAdmin,
          organizacionId: orgId,
          fechaCreacion: DateTime.now(),
          ultimoAcceso: DateTime.now(),
        );
        _currentOrg = org;
      }

      await _firestore.collection('users').doc(uid).set(user.toMap());
      _currentUser = user;
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

  Future<Organizacion?> crearOrganizacion({
    required String nombreOrg,
    required String emailAdmin,
    required String nombreAdmin,
    required String passwordTemp,
    String? nit,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailAdmin,
        password: passwordTemp,
      );
      final uid = cred.user!.uid;

      final orgId = _firestore.collection('organizaciones').doc().id;
      final org = Organizacion(
        id: orgId,
        nombre: nombreOrg,
        nit: nit,
        fechaCreacion: DateTime.now(),
        creadoPor: _currentUser?.uid ?? uid,
      );
      await _firestore.collection('organizaciones').doc(orgId).set(org.toMap());

      final admin = UserModel(
        uid: uid,
        email: emailAdmin,
        nombre: nombreAdmin,
        rol: UserRol.orgAdmin,
        organizacionId: orgId,
        fechaCreacion: DateTime.now(),
      );
      await _firestore.collection('users').doc(uid).set(admin.toMap());

      return org;
    } catch (e) {
      debugPrint('[AUTH] Error creating organization: $e');
      return null;
    }
  }

  Future<List<Organizacion>> getAllOrganizaciones() async {
    try {
      final snapshot = await _firestore
          .collection('organizaciones')
          .orderBy('fechaCreacion', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Organizacion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[AUTH] Error fetching organizaciones: $e');
      return [];
    }
  }

  Future<bool> toggleOrgActive(String orgId, bool active) async {
    try {
      await _firestore.collection('organizaciones').doc(orgId).update({'activa': active});
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error toggling org: $e');
      return false;
    }
  }

  Future<bool> deleteOrganizacion(String orgId) async {
    try {
      final usersSnap = await _firestore
          .collection('users')
          .where('organizacionId', isEqualTo: orgId)
          .get();
      for (final userDoc in usersSnap.docs) {
        await userDoc.reference.delete();
      }

      await _firestore.collection('organizaciones').doc(orgId).delete();
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error deleting organization: $e');
      return false;
    }
  }

  Future<List<UserModel>> getUsersByOrg(String orgId) async {
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
