import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../match/domain/match_setup.dart';
import '../../match/presentation/saved_matches_controller.dart';

/// Builds a team from what was typed: blank names get a default, and the
/// player list is cut or padded to [players].
Team buildTeam({
  required String name,
  required String fallbackName,
  required String playerNames,
  required int players,
  required String Function(int number) defaultPlayer,
}) {
  final typed = [
    for (final line in playerNames.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  return Team(
    name: name.trim().isEmpty ? fallbackName : name.trim(),
    players: [
      for (var i = 0; i < players; i++)
        i < typed.length ? typed[i] : defaultPlayer(i + 1),
    ],
  );
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNames = [TextEditingController(), TextEditingController()];
  final _playerNames = [TextEditingController(), TextEditingController()];
  final _overs = TextEditingController(text: '5');
  final _players = TextEditingController(text: '6');
  var _battingFirst = 0;
  var _rules = const MatchRules(oversPerInnings: 5, playersPerSide: 6);
  var _saving = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _teamNames) {
      controller.addListener(_rebuild);
    }
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    for (final controller in [
      ..._teamNames,
      ..._playerNames,
      _overs,
      _players,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final players = int.parse(_players.text);
    final rules = _rules.copyWith(
      oversPerInnings: int.parse(_overs.text),
      playersPerSide: players,
    );
    final teams = [
      for (final i in [0, 1])
        buildTeam(
          name: _teamNames[i].text,
          fallbackName: i == 0 ? l10n.defaultTeamOne : l10n.defaultTeamTwo,
          playerNames: _playerNames[i].text,
          players: players,
          defaultPlayer: l10n.defaultPlayerName,
        ),
    ];
    setState(() => _saving = true);
    final id = await ref
        .read(savedMatchesProvider.notifier)
        .create(teams: teams, battingFirst: _battingFirst, rules: rules);
    if (!mounted) return;
    setState(() => _saving = false);
    if (id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.storageError)));
      return;
    }
    context.go('/match/$id');
  }

  String? _validateRange(String? value, int min, int max, String message) {
    final number = int.tryParse(value ?? '');
    return number == null || number < min || number > max ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    String teamLabel(int i) => _teamNames[i].text.trim().isEmpty
        ? (i == 0 ? l10n.defaultTeamOne : l10n.defaultTeamTwo)
        : _teamNames[i].text.trim();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final i in [0, 1]) ...[
                Text(
                  i == 0 ? l10n.teamOne : l10n.teamTwo,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: Key('teamName-$i'),
                  controller: _teamNames[i],
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.teamName,
                    hintText: i == 0
                        ? l10n.defaultTeamOne
                        : l10n.defaultTeamTwo,
                  ),
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.playerNames),
                  children: [
                    TextField(
                      key: Key('playerNames-$i'),
                      controller: _playerNames[i],
                      minLines: 3,
                      maxLines: 12,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l10n.playerNamesHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('overs'),
                      controller: _overs,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.oversPerInnings,
                      ),
                      validator: (value) =>
                          _validateRange(value, 1, 99, l10n.oversInvalid),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      key: const Key('players'),
                      controller: _players,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.playersPerSide,
                      ),
                      validator: (value) =>
                          _validateRange(value, 2, 30, l10n.playersInvalid),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.battingFirst, style: text.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: [
                  for (final i in [0, 1])
                    ButtonSegment(
                      value: i,
                      label: Text(
                        teamLabel(i),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {_battingFirst},
                onSelectionChanged: (value) =>
                    setState(() => _battingFirst = value.single),
              ),
              const SizedBox(height: 24),
              Text(l10n.gullyRules, style: text.titleMedium),
              SwitchListTile(
                key: const Key('lastManStands'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.lastManStands),
                subtitle: Text(l10n.lastManStandsHint),
                value: _rules.lastManStands,
                onChanged: (value) => setState(
                  () => _rules = _rules.copyWith(lastManStands: value),
                ),
              ),
              SwitchListTile(
                key: const Key('wideRuns'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.wideGivesRun),
                value: _rules.wideRuns == 1,
                onChanged: (value) => setState(
                  () => _rules = _rules.copyWith(wideRuns: value ? 1 : 0),
                ),
              ),
              SwitchListTile(
                key: const Key('noBallRuns'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.noBallGivesRun),
                value: _rules.noBallRuns == 1,
                onChanged: (value) => setState(
                  () => _rules = _rules.copyWith(noBallRuns: value ? 1 : 0),
                ),
              ),
              SwitchListTile(
                key: const Key('freeHit'),
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.freeHit),
                value: _rules.freeHit,
                onChanged: (value) =>
                    setState(() => _rules = _rules.copyWith(freeHit: value)),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('startMatch'),
                onPressed: _saving ? null : _start,
                icon: const Icon(Icons.sports_cricket),
                label: Text(l10n.startMatch),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
