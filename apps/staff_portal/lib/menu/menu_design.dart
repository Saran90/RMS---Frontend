import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:models/models.dart';

// ── Menu page design tokens (aligned with dashboard / billing) ────────────────

const Color menuBg = Color(0xFFF5F0E8);
const Color menuCard = Color(0xFFFFFFFF);
const Color menuBorder = Color(0xFFE8E0D0);
const Color menuTitle = Color(0xFF1A1208);
const Color menuMuted = Color(0xFF9A8060);
const Color menuAccent = Color(0xFFBF4010);
const Color menuDivider = Color(0xFFF0E8D8);

/// Stat summary card for the menu page header.
class MenuStatCard extends StatelessWidget {
  const MenuStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: menuCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: menuBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: menuTitle,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: menuMuted)),
        ],
      ),
    );
  }
}

/// Orange-accent filter / tab chip.
class MenuChoiceChip extends StatelessWidget {
  const MenuChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? menuAccent.withValues(alpha: 0.12) : menuCard,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? menuAccent : menuBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? menuAccent : menuMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? menuAccent : menuMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state block used across menu tabs.
class MenuEmptyState extends StatelessWidget {
  const MenuEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: menuAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 36, color: menuAccent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: menuTitle,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 13, color: menuMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header for grouped menu items.
class MenuSectionHeader extends StatelessWidget {
  const MenuSectionHeader({
    required this.name,
    required this.count,
    super.key,
  });

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: menuAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: menuTitle,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: menuDivider,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: menuMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet surface styling for add/edit forms.
class MenuSheetScaffold extends StatelessWidget {
  const MenuSheetScaffold({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: menuCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: menuBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: menuTitle,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary CTA button for menu forms.
class MenuPrimaryButton extends StatelessWidget {
  const MenuPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: menuAccent,
          foregroundColor: Colors.white,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Inline error banner for forms.
class MenuFormError extends StatelessWidget {
  const MenuFormError({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.error),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error, fontSize: 13),
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

/// Compact horizontal category tile for the menu grid.
class MenuCategoryTile extends StatelessWidget {
  const MenuCategoryTile({
    required this.name,
    required this.displayOrder,
    this.description,
    this.isDeleting = false,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final String name;
  final int displayOrder;
  final String? description;
  final bool isDeleting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: menuCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: menuBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: menuAccent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: menuAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        size: 17,
                        color: menuAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: menuTitle,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description != null &&
                              description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: menuMuted,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: menuDivider,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$displayOrder',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: menuMuted,
                        ),
                      ),
                    ),
                    _CompactIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit $name',
                      color: menuAccent,
                      onTap: isDeleting ? null : onEdit,
                    ),
                    isDeleting
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: menuMuted,
                              ),
                            ),
                          )
                        : _CompactIconButton(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete $name',
                            color: AppTheme.error,
                            onTap: onDelete,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon, size: 17, color: onTap == null ? menuMuted : color),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

// ── Menu item tile ────────────────────────────────────────────────────────────

String _formatMenuPrice(double price) {
  return price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toStringAsFixed(2);
}

/// Compact horizontal menu item tile for the items grid.
class MenuItemTile extends StatelessWidget {
  const MenuItemTile({
    required this.name,
    required this.price,
    required this.dietaryType,
    required this.isAvailable,
    required this.onEdit,
    required this.onAvailabilityChanged,
    super.key,
  });

  final String name;
  final double price;
  final DietaryType dietaryType;
  final bool isAvailable;
  final VoidCallback onEdit;
  final ValueChanged<bool> onAvailabilityChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = isAvailable ? AppTheme.success : menuMuted;

    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? menuCard : menuDivider.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: menuBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: menuBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: menuBorder),
                      ),
                      child: Center(child: DietaryBadge(type: dietaryType)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isAvailable ? menuTitle : menuMuted,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatMenuPrice(price)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isAvailable ? menuAccent : menuMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : menuDivider,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAvailable ? 'On' : 'Off',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.68,
                          child: Switch(
                            value: isAvailable,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: onAvailabilityChanged,
                          ),
                        ),
                      ],
                    ),
                    _CompactIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit $name',
                      color: menuAccent,
                      onTap: onEdit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
