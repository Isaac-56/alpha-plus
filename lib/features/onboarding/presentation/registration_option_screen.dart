import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RegistrationOptionScreen extends StatefulWidget {
  const RegistrationOptionScreen({
    required this.title,
    required this.options,
    super.key,
    this.selected,
    this.colors = const <String, Color>{},
  });

  final String title;
  final List<String> options;
  final String? selected;
  final Map<String, Color> colors;

  @override
  State<RegistrationOptionScreen> createState() =>
      _RegistrationOptionScreenState();
}

class _RegistrationOptionScreenState extends State<RegistrationOptionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filtered = widget.options
        .where(
          (String option) =>
              option.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: TextField(
                controller: _searchController,
                autofocus: widget.options.length > 8,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (String value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching option'))
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final String option = filtered[index];
                        final bool selected = option == widget.selected;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 7,
                          ),
                          leading: widget.colors[option] == null
                              ? null
                              : Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: widget.colors[option],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ),
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
