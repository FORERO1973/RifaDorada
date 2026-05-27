import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class RegistrationStepper extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final VoidCallback onNext;
  final VoidCallback? onPrevious;
  final Widget child;
  final bool isLastStep;
  final bool isLoading;

  const RegistrationStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.onNext,
    this.onPrevious,
    required this.child,
    this.isLastStep = false,
    this.isLoading = false,
  });

  @override
  State<RegistrationStepper> createState() => _RegistrationStepperState();
}

class _RegistrationStepperState extends State<RegistrationStepper> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepperHeader(isDesktop),
          const SizedBox(height: 20),
          _buildProgressLine(),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(widget.currentStep),
              child: widget.child,
            ),
          ),
          const SizedBox(height: 24),
          _buildNavigationButtons(isDesktop),
        ],
      ),
    );
  }

  Widget _buildStepperHeader(bool isDesktop) {
    return Row(
      children: List.generate(widget.totalSteps, (index) {
        final isActive = index <= widget.currentStep;
        final isCurrent = index == widget.currentStep;
        final isCompleted = index < widget.currentStep;

        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isDesktop ? 40 : 34,
                height: isDesktop ? 40 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? AppTheme.goldGradient : null,
                  color: isActive ? null : AppTheme.surfaceColor,
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.primaryColor
                        : (isCompleted
                            ? AppTheme.primaryColor.withValues(alpha: 0.3)
                            : AppTheme.dividerColor),
                    width: isCurrent ? 2 : 1,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: AppTheme.backgroundColor, size: 20)
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            fontSize: isDesktop ? 14 : 12,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? AppTheme.backgroundColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.stepLabels[index],
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isDesktop ? 11 : 10,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent
                      ? AppTheme.primaryColor
                      : (isActive
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProgressLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / widget.totalSteps;
        final progressWidth = stepWidth * (widget.currentStep + 1);

        return Stack(
          children: [
            Container(
              height: 2,
              color: AppTheme.dividerColor.withValues(alpha: 0.3),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: progressWidth,
              height: 2,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationButtons(bool isDesktop) {
    return Row(
      children: [
        if (widget.currentStep > 0 && widget.onPrevious != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onPrevious,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Anterior'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        if (widget.currentStep > 0 && widget.onPrevious != null)
          const SizedBox(width: 12),
        Expanded(
          flex: widget.currentStep > 0 ? 2 : 1,
          child: ElevatedButton.icon(
            onPressed: widget.isLoading ? null : widget.onNext,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    widget.isLastStep
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(widget.isLastStep ? 'REGISTRARME' : 'SIGUIENTE'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
