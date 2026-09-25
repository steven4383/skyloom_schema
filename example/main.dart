import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skyloom_schema/skyloom_schema.dart';

void main() => runApp(const SkyloomDocsApp());

class SkyloomDocsApp extends StatefulWidget {
  const SkyloomDocsApp({super.key});

  @override
  State<SkyloomDocsApp> createState() => _SkyloomDocsAppState();
}

class _SkyloomDocsAppState extends State<SkyloomDocsApp> {
  final themeController = SkyloomThemeController();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final skyloomTheme = themeController.theme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Skyloom Schema Docs',
          themeMode: themeController.themeMode,
          theme: skyloomTheme.lightTheme,
          darkTheme: skyloomTheme.darkTheme,
          home: DocsShell(themeController: themeController),
        );
      },
    );
  }

  @override
  void dispose() {
    themeController.dispose();
    super.dispose();
  }
}

class DocsShell extends StatefulWidget {
  const DocsShell({required this.themeController, super.key});

  final SkyloomThemeController themeController;

  @override
  State<DocsShell> createState() => _DocsShellState();
}

class _DocsShellState extends State<DocsShell> {
  int selected = 0;

  static const destinations = [
    ('Components', Icons.grid_view_outlined, Icons.grid_view),
    ('Themes', Icons.palette_outlined, Icons.palette),
    ('Schema API', Icons.data_object_outlined, Icons.data_object),
    ('Guides', Icons.menu_book_outlined, Icons.menu_book),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        final desktop = size.maxWidth >= 960;
        final content = IndexedStack(
          index: selected,
          children: [
            const ComponentCatalogPage(),
            ThemeShowcasePage(controller: widget.themeController),
            const SchemaReferencePage(),
            const FeatureGuidesPage(),
          ],
        );
        return Scaffold(
          appBar: desktop
              ? null
              : AppBar(
                  title: const _Brand(showName: true),
                  actions: [
                    _ThemeControls(controller: widget.themeController),
                    const SizedBox(width: 8),
                  ],
                ),
          body: desktop
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selected,
                      onDestinationSelected: selectPage,
                      extended: size.maxWidth >= 1240,
                      minExtendedWidth: 220,
                      leading: const Padding(
                        padding: EdgeInsets.fromLTRB(16, 22, 16, 30),
                        child: _Brand(showName: true),
                      ),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ThemeControls(
                                  controller: widget.themeController,
                                  direction: Axis.vertical,
                                ),
                                const SizedBox(height: 12),
                                const _VersionBadge(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      destinations: [
                        for (final item in destinations)
                          NavigationRailDestination(
                            icon: Icon(item.$2),
                            selectedIcon: Icon(item.$3),
                            label: Text(item.$1),
                          ),
                      ],
                    ),
                    VerticalDivider(
                      width: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: selectPage,
                  destinations: [
                    for (final item in destinations)
                      NavigationDestination(
                        icon: Icon(item.$2),
                        selectedIcon: Icon(item.$3),
                        label: item.$1,
                      ),
                  ],
                ),
        );
      },
    );
  }

  void selectPage(int value) => setState(() => selected = value);
}

class _ThemeControls extends StatelessWidget {
  const _ThemeControls({
    required this.controller,
    this.direction = Axis.horizontal,
  });

  final SkyloomThemeController controller;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Flex(
      direction: direction,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('theme-mode-toggle'),
          tooltip: dark ? 'Use light mode' : 'Use true-black dark mode',
          onPressed: () =>
              controller.toggleBrightness(Theme.of(context).brightness),
          icon: Icon(
            dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          ),
        ),
        IconButton(
          key: const Key('visual-style-toggle'),
          tooltip: controller.visualStyle == SkyloomVisualStyle.standard
              ? 'Use brutalism style'
              : 'Use standard style',
          onPressed: controller.toggleVisualStyle,
          icon: Icon(
            controller.visualStyle == SkyloomVisualStyle.standard
                ? Icons.crop_square
                : Icons.rounded_corner,
          ),
        ),
      ],
    );
  }
}

class ComponentCatalogPage extends StatefulWidget {
  const ComponentCatalogPage({super.key});

  @override
  State<ComponentCatalogPage> createState() => _ComponentCatalogPageState();
}

class _ComponentCatalogPageState extends State<ComponentCatalogPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = componentDocs
        .where(
          (item) => '${item.title} ${item.type} ${item.summary}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('components'),
      slivers: [
        SliverToBoxAdapter(
          child: _Hero(
            onQueryChanged: (value) => setState(() => query = value),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 3
                        : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 16) / columns;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final item in filtered)
                          SizedBox(
                            width: width,
                            child: ComponentDocCard(doc: item),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onQueryChanged});
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Pill(
                icon: Icons.widgets_outlined,
                label: '14 built-in field types',
              ),
              const SizedBox(height: 18),
              Text(
                'Component explorer',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Preview every renderer, inspect its JSON schema, and copy a working definition into your app.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  onChanged: onQueryChanged,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search fields and capabilities',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComponentDocCard extends StatefulWidget {
  const ComponentDocCard({required this.doc, super.key});
  final ComponentDoc doc;

  @override
  State<ComponentDocCard> createState() => _ComponentDocCardState();
}

class _ComponentDocCardState extends State<ComponentDocCard> {
  bool expanded = false;
  int uploadSequence = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.doc.icon,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doc.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'FormType.${widget.doc.constant}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.doc.summary,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 10),
                  Text('Live preview', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 12),
                  SkyloomForm.fromJson(
                    schema: widget.doc.schema,
                    layout: SkyloomFormLayout.column,
                    showSubmitButton: false,
                    showErrorSummary: false,
                    validationMode: SkyloomValidationMode.onBlur,
                    fileUploadHandlers: widget.doc.type == FormType.file
                        ? {
                            'demoUpload': (request) async {
                              uploadSequence++;
                              return [
                                SkyloomUploadedFile(
                                  id: 'demo_$uploadSequence',
                                  name: 'portfolio.pdf',
                                  mimeType: 'application/pdf',
                                  size: 248312,
                                ),
                              ];
                            },
                          }
                        : const {},
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Schema', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Copy schema',
                        onPressed: copySchema,
                        icon: const Icon(Icons.copy_outlined, size: 19),
                      ),
                    ],
                  ),
                  _CodeBlock(value: prettyJson(widget.doc.schema)),
                  const SizedBox(height: 14),
                  Text('Key properties', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(
                    widget.doc.properties,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> copySchema() async {
    await Clipboard.setData(ClipboardData(text: prettyJson(widget.doc.schema)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Schema copied'),
      ),
    );
  }
}

const _themePreviewSchema = <String, Object?>{
  'id': 'theme_preview',
  'fields': [
    {
      'key': 'name',
      'type': FormType.text,
      'label': 'Project name',
      'validation': {'required': true},
    },
    {
      'key': 'role',
      'type': FormType.select,
      'label': 'Workspace role',
      'options': [
        {'label': 'Developer', 'value': 'developer'},
        {'label': 'Designer', 'value': 'designer'},
      ],
    },
    {
      'key': 'channels',
      'type': FormType.chip,
      'label': 'Notifications',
      'options': [
        {'label': 'Email', 'value': 'email'},
        {'label': 'Push', 'value': 'push'},
        {'label': 'Weekly digest', 'value': 'digest'},
      ],
      'visualHints': {FormUiHint.multiSelect: true},
    },
    {
      'key': 'enabled',
      'type': FormType.switchField,
      'label': 'Enable workspace',
      'defaultValue': true,
    },
  ],
};

class ThemeShowcasePage extends StatelessWidget {
  const ThemeShowcasePage({required this.controller, super.key});

  final SkyloomThemeController controller;

  @override
  Widget build(BuildContext context) {
    return _DocsPage(
      eyebrow: 'APPEARANCE',
      title: 'Standard and brutalism themes',
      description:
          'Compare both built-in styles with the same generated form. The previews follow the current light or dark mode.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 840 ? 2 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 18) / columns;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                SizedBox(
                  width: width,
                  child: _ThemePreview(
                    title: 'Standard',
                    description:
                        'Rounded Material 3 surfaces with quiet borders and elevation.',
                    visualStyle: SkyloomVisualStyle.standard,
                    controller: controller,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _ThemePreview(
                    title: 'Brutalism',
                    description:
                        'Square corners, heavy outlines, strong type, and hard elevation.',
                    visualStyle: SkyloomVisualStyle.brutalism,
                    controller: controller,
                  ),
                ),
              ],
            );
          },
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Use either style',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const _CodeBlock(
                  value:
                      "const appearance = SkyloomTheme(\n  seedColor: Colors.teal,\n  visualStyle: SkyloomVisualStyle.brutalism,\n);\n\nMaterialApp(\n  theme: appearance.lightTheme,\n  darkTheme: appearance.darkTheme,\n  themeMode: ThemeMode.system,\n);",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.title,
    required this.description,
    required this.visualStyle,
    required this.controller,
  });

  final String title;
  final String description;
  final SkyloomVisualStyle visualStyle;
  final SkyloomThemeController controller;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final appearance = SkyloomTheme(
      seedColor: controller.seedColor,
      visualStyle: visualStyle,
      pureBlackDark: controller.pureBlackDark,
    );
    final previewTheme = dark ? appearance.darkTheme : appearance.lightTheme;
    final active = controller.visualStyle == visualStyle;
    return Theme(
      data: previewTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: theme.scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          const Chip(
                            avatar: Icon(Icons.check, size: 16),
                            label: Text('Active'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SkyloomForm.fromJson(
                      schema: _themePreviewSchema,
                      layout: SkyloomFormLayout.column,
                      initialValues: const {
                        'name': 'Skyloom workspace',
                        'role': 'developer',
                        'channels': ['email', 'push'],
                      },
                      submitButtonLabel: 'Save preview',
                      onSubmit: (_) {},
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: ValueKey('apply-${visualStyle.name}'),
                      onPressed: active
                          ? null
                          : () => controller.setVisualStyle(visualStyle),
                      icon: Icon(active ? Icons.check : Icons.palette_outlined),
                      label: Text(active ? '$title active' : 'Use $title'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SchemaReferencePage extends StatelessWidget {
  const SchemaReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocsPage(
      eyebrow: 'SCHEMA 1.0',
      title: 'Schema API reference',
      description:
          'The JSON-compatible contract parsed by SchemaParser and rendered by SkyloomForm.',
      children: const [
        _ReferenceSection(
          title: 'Form object',
          description:
              'Top-level definition for identity, fields, presentation, sections, and workflow steps.',
          rows: [
            ('id', 'String', 'Required', 'Stable form identifier.'),
            (
              'schemaVersion',
              'String',
              'Optional',
              'Schema contract version; currently 1.0.',
            ),
            ('title', 'String', 'Optional', 'Human-readable form title.'),
            ('description', 'String', 'Optional', 'Supporting description.'),
            (
              'fields',
              'List<Field>',
              'Required',
              'Root field definitions with unique keys.',
            ),
            (
              'uiSchema',
              'Map',
              'Optional',
              'Renderer, order, responsive spans, and visual hints.',
            ),
            (
              'sections',
              'List<Section>',
              'Optional',
              'Ordered or collapsible field groups.',
            ),
            (
              'steps',
              'List<Step>',
              'Optional',
              'Ordered conditional workflow pages.',
            ),
            ('metadata', 'Map', 'Optional', 'Application-owned JSON metadata.'),
          ],
        ),
        _ReferenceSection(
          title: 'Field object',
          description:
              'Common properties accepted by fields. Type-specific cards document additional properties.',
          rows: [
            (
              'key',
              'String',
              'Required*',
              'Unique key and submitted-value path.',
            ),
            ('type', 'String', 'Required', 'Built-in or custom renderer type.'),
            ('label', 'String', 'Optional', 'Visible field label.'),
            ('description', 'String', 'Optional', 'Longer explanatory copy.'),
            (
              'helperText',
              'String',
              'Optional',
              'Supporting text near the control.',
            ),
            ('placeholder', 'String', 'Optional', 'Empty-value prompt.'),
            (
              'defaultValue',
              'JSON value',
              'Optional',
              'Initial value when no explicit value is supplied.',
            ),
            ('required', 'bool', 'Optional', 'Static required state.'),
            ('disabled', 'bool', 'Optional', 'Static disabled state.'),
            ('readOnly', 'bool', 'Optional', 'Static read-only state.'),
            ('hidden', 'bool', 'Optional', 'Static hidden state.'),
            (
              'validation',
              'Map',
              'Optional',
              'Built-in and named custom validation rules.',
            ),
          ],
          footnote: '* Array item schemas do not require a key.',
        ),
        _ReferenceSection(
          title: 'Validation rules',
          description:
              'Rules run through the controller and return structured field errors.',
          rows: [
            (
              'required',
              'bool',
              'Presence',
              'Rejects null, blank, false, or empty values.',
            ),
            (
              'minLength / maxLength',
              'int',
              'Length',
              'String or collection length bounds.',
            ),
            ('min / max', 'num', 'Numeric', 'Inclusive numeric bounds.'),
            ('minDate / maxDate', 'ISO date', 'Date', 'Inclusive date bounds.'),
            ('email / url', 'bool', 'Format', 'Common format validation.'),
            (
              'pattern / regex',
              'String',
              'Format',
              'Pattern-based validation.',
            ),
            (
              'sameAs / notSameAs',
              'field path',
              'Cross-field',
              'Equality comparisons.',
            ),
            (
              'greaterThan / lessThan',
              'field path',
              'Cross-field',
              'Numeric or ISO-date comparison.',
            ),
            (
              'custom',
              'String/List',
              'Extension',
              'Named application validators.',
            ),
          ],
        ),
      ],
    );
  }
}

class FeatureGuidesPage extends StatelessWidget {
  const FeatureGuidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _DocsPage(
      eyebrow: 'RECIPES',
      title: 'Feature guides',
      description:
          'Production patterns for responsive forms, conditions, remote data, and workflows.',
      children: const [
        _GuideCard(
          title: 'Typed Dart authoring',
          icon: Icons.code_outlined,
          body:
              'Use typed field factories for local schemas and keep maps for definitions received as JSON.',
          code:
              "final schema = SkyloomSchema.form(\n  id: 'profile',\n  fields: [\n    SkyloomField.text(\n      key: 'name',\n      validation: SkyloomValidation.rules(required: true),\n    ),\n  ],\n);",
        ),
        _GuideCard(
          title: 'Responsive layout',
          icon: Icons.devices_outlined,
          body:
              'Use twelve-column spans in uiSchema. Missing spans default to 12, so every field remains usable on every screen.',
          code:
              "'uiSchema': {\n  'firstName': {\n    'layout': {'mobile': 12, 'tablet': 6, 'desktop': 6}\n  }\n}",
        ),
        _GuideCard(
          title: 'Conditional state',
          icon: Icons.alt_route,
          body:
              'Conditions can drive visibility, required, enabled, disabled, and read-only state using field paths and nested groups.',
          code:
              "'visibleWhen': {\n  'field': 'accountType',\n  'equals': 'business'\n}",
        ),
        _GuideCard(
          title: 'Dependencies and remote options',
          icon: Icons.sync_alt,
          body:
              'Declare dependency edges in JSON and register application-owned handlers in Dart. Network code never enters the schema.',
          code:
              "'dependsOn': ['country'],\n'dataSource': {'handler': 'states'},\n'dependencyConfig': {\n  'clearOnChange': true,\n  'reloadDataOnChange': true\n}",
        ),
        _GuideCard(
          title: 'Multi-step workflows',
          icon: Icons.route_outlined,
          body:
              'Assign each root field to one ordered step. Next validates the current step; steps may also be conditional.',
          code:
              "'steps': [\n  {'id': 'profile', 'title': 'Profile', 'fields': ['name']},\n  {'id': 'contact', 'title': 'Contact', 'fields': ['email']}\n]",
        ),
        _GuideCard(
          title: 'Controller integration',
          icon: Icons.gamepad_outlined,
          body:
              'Use SkyloomFormController for programmatic values, validation, step navigation, server errors, reset, and persistence.',
          code:
              "final controller = SkyloomFormController(schema: schema);\ncontroller.setValue('email', 'dev@example.com');\nawait controller.nextStep();\nfinal values = controller.values;",
        ),
      ],
    );
  }
}

class _DocsPage extends StatelessWidget {
  const _DocsPage({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
  });
  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      key: PageStorageKey(title),
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 60),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 30),
                ...children.map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReferenceSection extends StatelessWidget {
  const _ReferenceSection({
    required this.title,
    required this.description,
    required this.rows,
    this.footnote,
  });
  final String title;
  final String description;
  final List<(String, String, String, String)> rows;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        children: [
          const Divider(),
          for (final row in rows) _PropertyRow(row: row),
          if (footnote != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(footnote!, style: theme.textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.row});
  final (String, String, String, String) row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.$1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${row.$2} · ${row.$3}',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 4),
                Text(row.$4),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  row.$1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(flex: 2, child: Text(row.$2)),
              Expanded(flex: 2, child: Text(row.$3)),
              Expanded(flex: 5, child: Text(row.$4)),
            ],
          );
        },
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.icon,
    required this.body,
    required this.code,
  });
  final String title;
  final IconData icon;
  final String body;
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        key: PageStorageKey('guide-$title'),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(icon),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(body),
        ),
        children: [
          const SizedBox(height: 10),
          _CodeBlock(value: code),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        key: PageStorageKey('code-$value'),
        value,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.45,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({this.showName = false});
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: Image.asset(
            'assets/branding/skyloom-logo-mark.png',
            package: 'skyloom_schema',
            fit: BoxFit.contain,
            semanticLabel: 'Skyloom logo',
          ),
        ),
        if (showName) ...[
          const SizedBox(width: 10),
          Text(
            'Skyloom',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge();
  @override
  Widget build(BuildContext context) =>
      const _Pill(icon: Icons.code, label: 'Schema 1.0');
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.onSecondaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String prettyJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);

Map<String, Object?> formFor(
  Map<String, Object?> field, {
  Map<String, Object?> ui = const {},
}) => {
  'id': 'preview_${field['key']}',
  'fields': [field],
  if (ui.isNotEmpty) 'uiSchema': {field['key'] as String: ui},
};

class ComponentDoc {
  const ComponentDoc({
    required this.title,
    required this.type,
    required this.constant,
    required this.summary,
    required this.properties,
    required this.icon,
    required this.schema,
  });
  final String title;
  final String type;
  final String constant;
  final String summary;
  final String properties;
  final IconData icon;
  final Map<String, Object?> schema;
}

final componentDocs = <ComponentDoc>[
  ComponentDoc(
    title: 'Text',
    type: FormType.text,
    constant: 'text',
    icon: Icons.short_text,
    summary: 'Single-line text input for names, labels, and general strings.',
    properties:
        'placeholder · helperText · defaultValue · minLength · maxLength · pattern · custom',
    schema: formFor({
      'key': 'name',
      'type': FormType.text,
      'label': 'Full name',
      'placeholder': 'Ada Lovelace',
      'validation': {'required': true, 'minLength': 2},
    }),
  ),
  ComponentDoc(
    title: 'Email',
    type: FormType.email,
    constant: 'email',
    icon: Icons.alternate_email,
    summary:
        'Email-optimized keyboard and autofill with optional format validation.',
    properties: 'placeholder · helperText · email · asyncValidation · custom',
    schema: formFor({
      'key': 'email',
      'type': FormType.email,
      'label': 'Email address',
      'placeholder': 'ada@example.com',
      'validation': {'required': true, 'email': true},
    }),
  ),
  ComponentDoc(
    title: 'Password',
    type: FormType.password,
    constant: 'password',
    icon: Icons.password,
    summary: 'Obscured text input for credentials and sensitive strings.',
    properties:
        'placeholder · helperText · minLength · maxLength · pattern · custom',
    schema: formFor({
      'key': 'password',
      'type': FormType.password,
      'label': 'Password',
      'helperText': 'At least 8 characters',
      'validation': {'required': true, 'minLength': 8},
    }),
  ),
  ComponentDoc(
    title: 'Number',
    type: FormType.number,
    constant: 'number',
    icon: Icons.numbers,
    summary: 'Numeric input that emits JSON-compatible numeric values.',
    properties: 'defaultValue · min · max · greaterThan · lessThan · custom',
    schema: formFor({
      'key': 'experience',
      'type': FormType.number,
      'label': 'Years of experience',
      'validation': {'min': 0, 'max': 60},
    }),
  ),
  ComponentDoc(
    title: 'Textarea',
    type: FormType.textarea,
    constant: 'textarea',
    icon: Icons.notes,
    summary: 'Multi-line input for descriptions, comments, and longer content.',
    properties: 'placeholder · helperText · minLength · maxLength · custom',
    schema: formFor({
      'key': 'bio',
      'type': FormType.textarea,
      'label': 'Biography',
      'placeholder': 'Tell us about yourself…',
      'validation': {'maxLength': 240},
    }),
  ),
  ComponentDoc(
    title: 'Checkbox',
    type: FormType.checkbox,
    constant: 'checkbox',
    icon: Icons.check_box_outlined,
    summary: 'Boolean checkbox suited to consent and independent options.',
    properties: 'defaultValue · required · disabled · readOnly · conditions',
    schema: formFor({
      'key': 'terms',
      'type': FormType.checkbox,
      'label': 'I agree to the terms',
      'validation': {'required': true},
    }),
  ),
  ComponentDoc(
    title: 'Switch',
    type: FormType.switchField,
    constant: 'switchField',
    icon: Icons.toggle_on_outlined,
    summary: 'Boolean switch for settings that take effect immediately.',
    properties:
        'defaultValue · disabled · readOnly · enabledWhen · disabledWhen',
    schema: formFor({
      'key': 'updates',
      'type': FormType.switchField,
      'label': 'Product updates',
      'defaultValue': true,
    }),
  ),
  ComponentDoc(
    title: 'Radio',
    type: FormType.radio,
    constant: 'radio',
    icon: Icons.radio_button_checked,
    summary: 'Single selection from a small, always-visible option set.',
    properties:
        'options · dataSource · defaultValue · radioDirection · required',
    schema: formFor(
      {
        'key': 'workMode',
        'type': FormType.radio,
        'label': 'Work mode',
        'options': [
          {'label': 'Remote', 'value': 'remote'},
          {'label': 'Hybrid', 'value': 'hybrid'},
        ],
      },
      ui: {
        'visualHints': {FormUiHint.radioDirection: FormUiDirection.row},
      },
    ),
  ),
  ComponentDoc(
    title: 'Select',
    type: FormType.select,
    constant: 'select',
    icon: Icons.arrow_drop_down_circle_outlined,
    summary:
        'Compact single selection with static or asynchronously loaded options.',
    properties:
        'options · dataSource · dependsOn · dependencyConfig · required',
    schema: formFor({
      'key': 'role',
      'type': FormType.select,
      'label': 'Role',
      'options': [
        {'label': 'Developer', 'value': 'developer'},
        {'label': 'Designer', 'value': 'designer'},
      ],
    }),
  ),
  ComponentDoc(
    title: 'Date',
    type: FormType.date,
    constant: 'date',
    icon: Icons.calendar_month_outlined,
    summary: 'Material date picker that stores an ISO-compatible date value.',
    properties: 'defaultValue · minDate · maxDate · greaterThan · lessThan',
    schema: formFor({
      'key': 'startDate',
      'type': FormType.date,
      'label': 'Start date',
      'validation': {'required': true},
    }),
  ),
  ComponentDoc(
    title: 'File',
    type: FormType.file,
    constant: 'file',
    icon: Icons.upload_file_outlined,
    summary:
        'Application-owned upload flow with typed metadata, progress, retry, and removal.',
    properties:
        'upload.handler · accept · maxBytes · multiple · minFiles · maxFiles',
    schema: formFor({
      'key': 'resume',
      'type': FormType.file,
      'label': 'Resume',
      'helperText': 'PDF, up to 5 MB',
      'upload': {
        'handler': 'demoUpload',
        'accept': ['application/pdf'],
        'maxBytes': 5000000,
      },
    }),
  ),
  ComponentDoc(
    title: 'Chip',
    type: FormType.chip,
    constant: 'chip',
    icon: Icons.sell_outlined,
    summary:
        'ChoiceChip for one value or FilterChip for a JSON list of values.',
    properties: 'options · dataSource · visualHints.multiSelect · defaultValue',
    schema: formFor(
      {
        'key': 'skills',
        'type': FormType.chip,
        'label': 'Skills',
        'options': [
          {'label': 'Flutter', 'value': 'flutter'},
          {'label': 'Dart', 'value': 'dart'},
          {'label': 'Testing', 'value': 'testing'},
        ],
      },
      ui: {
        'visualHints': {FormUiHint.multiSelect: true},
      },
    ),
  ),
  ComponentDoc(
    title: 'Object',
    type: FormType.object,
    constant: 'object',
    icon: Icons.account_tree_outlined,
    summary: 'Recursive field group that preserves a nested JSON object.',
    properties:
        'fields · label · description · nested validation and conditions',
    schema: formFor({
      'key': 'address',
      'type': FormType.object,
      'label': 'Address',
      'fields': [
        {'key': 'city', 'type': FormType.text, 'label': 'City'},
        {'key': 'country', 'type': FormType.text, 'label': 'Country'},
      ],
    }),
  ),
  ComponentDoc(
    title: 'Array',
    type: FormType.array,
    constant: 'array',
    icon: Icons.view_list_outlined,
    summary:
        'Repeatable primitive, object, or nested-array items with built-in controls.',
    properties:
        'items · minItems · maxItems · defaultItem · add · remove · duplicate · reorder',
    schema: formFor({
      'key': 'contacts',
      'type': FormType.array,
      'label': 'Emergency contacts',
      'minItems': 1,
      'maxItems': 3,
      'items': {
        'type': FormType.object,
        'fields': [
          {'key': 'name', 'type': FormType.text, 'label': 'Name'},
          {'key': 'phone', 'type': FormType.text, 'label': 'Phone'},
        ],
      },
    }),
  ),
];
