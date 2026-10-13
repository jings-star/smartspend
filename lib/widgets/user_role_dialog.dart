import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

class _Role {
  final String name;
  final IconData icon;
  const _Role(this.name, this.icon);
}

const _roles = <_Role>[
  _Role('Student', Icons.school_outlined),
  _Role('Working Adult', Icons.work_outline),
];

/// Shows the "Select your role here !" dialog.
/// Returns 'Student' or 'Working Adult', or null if dismissed.
///
///   final role = await showUserRoleDialog(context, selected: current);
Future<String?> showUserRoleDialog(BuildContext context,
    {required String selected}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _UserRoleDialog(selected: selected),
  );
}

class _UserRoleDialog extends StatefulWidget {
  final String selected;
  const _UserRoleDialog({required this.selected});

  @override
  State<_UserRoleDialog> createState() => _UserRoleDialogState();
}

class _UserRoleDialogState extends State<_UserRoleDialog> {
  late String _picked = widget.selected;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 0, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Select your role here !',
                        style: AppTheme.heading(17)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.backgroundDeep,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final r in _roles) ...[
              _RoleCard(
                role: r,
                selected: r.name == _picked,
                onTap: () => setState(() => _picked = r.name),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 2),
            PrimaryButton(
              label: 'Confirm',
              color: AppColors.sage,
              onPressed: () => Navigator.pop(context, _picked),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _Role role;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageTint : AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.sage : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(role.icon, size: 20, color: AppColors.terracottaDark),
            const SizedBox(width: 18),
            Expanded(
              child: Text(role.name,
                  style: AppTheme.body(13, weight: FontWeight.w600)),
            ),
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.sage : AppColors.textFaint,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.sage,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
