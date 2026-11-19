import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../site/site_theme.dart';

/// A settings card with a title.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, this.description, required this.children});

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SiteCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(description!,
                    style: const TextStyle(fontSize: 13, color: SiteColors.grey600, height: 1.5)),
              ),
            const SizedBox(height: 4),
            ...children,
          ]),
        ),
      );
}

/// Title, optional API name chip and description of a setting row.
class SettingLabel extends StatelessWidget {
  const SettingLabel({super.key, required this.title, this.api, this.description});

  final String title;
  final String? api;
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: SiteColors.grey800)),
              if (api != null) ApiChip(api!),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(description!, style: const TextStyle(fontSize: 13, color: SiteColors.grey500)),
          ],
        ],
      );
}

/// The name of the toolkit API a setting maps to.
class ApiChip extends StatelessWidget {
  const ApiChip(this.api, {super.key});

  final String api;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: SiteColors.grey100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(api,
            style: const TextStyle(
                fontSize: 11, fontFamily: 'monospace', color: SiteColors.grey600)),
      );
}

/// Dims and disables [child] when [enabled] is false.
class Dimmed extends StatelessWidget {
  const Dimmed({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.4,
        child: IgnorePointer(ignoring: !enabled, child: child),
      );
}

class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    this.api,
    this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String? api;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Dimmed(
        enabled: enabled,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(child: SettingLabel(title: title, api: api, description: description)),
              const SizedBox(width: 12),
              Switch(value: value, onChanged: onChanged),
            ]),
          ),
        ),
      );
}

class FieldRow extends StatelessWidget {
  const FieldRow({
    super.key,
    required this.title,
    this.api,
    this.description,
    required this.child,
    this.enabled = true,
  });

  final String title;
  final String? api;
  final String? description;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Dimmed(
        enabled: enabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SettingLabel(title: title, api: api, description: description),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );
}

class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.title,
    this.api,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  });

  final String title;
  final String? api;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Dimmed(
        enabled: enabled,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: SettingLabel(title: title, api: api)),
              Text(valueLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SiteColors.blue,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
            ]),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ]),
        ),
      );
}

/// Mutually exclusive choice: a grey track with the selected segment raised in white.
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.trackColor = SiteColors.grey100,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  /// The track behind the segments; use a darker one on a grey page background.
  final Color trackColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                key: ValueKey('segment-${entry.key}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: const Cubic(0.22, 0.61, 0.36, 1),
                  height: 34,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: entry.key == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: entry.key == value ? SiteShadows.card : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: entry.key == value ? FontWeight.w600 : FontWeight.w500,
                        color: entry.key == value ? SiteColors.grey900 : SiteColors.grey500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// A row of colour swatches.
class ColorChoice extends StatelessWidget {
  const ColorChoice({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 10, children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? Colors.white : SiteColors.grey200,
                  width: 3,
                ),
                boxShadow: [
                  if (selected == c) const BoxShadow(color: SiteColors.grey400, spreadRadius: 2),
                ],
              ),
            ),
          ),
      ]);
}

/// Code on a dark background with a copy button.
class CodeBlock extends StatefulWidget {
  const CodeBlock({
    super.key,
    required this.code,
    required this.copyLabel,
    required this.copiedLabel,
  });

  final String code;
  final String copyLabel;
  final String copiedLabel;

  @override
  State<CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<CodeBlock> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: SiteColors.grey900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 14, 44, 14),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.55,
                color: Color(0xFFE5E8EB),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: _copied ? widget.copiedLabel : widget.copyLabel,
              color: Colors.white70,
              iconSize: 18,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.code));
                if (!mounted) return;
                setState(() => _copied = true);
                await Future<void>.delayed(const Duration(seconds: 2));
                if (mounted) setState(() => _copied = false);
              },
              icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
            ),
          ),
        ]),
      );
}
