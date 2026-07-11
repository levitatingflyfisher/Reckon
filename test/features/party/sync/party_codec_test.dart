import 'package:flutter_test/flutter_test.dart';
import 'package:reckon/features/party/domain/entities/ballot.dart';
import 'package:reckon/features/party/domain/entities/party.dart';
import 'package:reckon/features/party/sync/party_codec.dart';

/// The codec is the single definition of the wire shapes that ride inside
/// encrypted blobs. Persistent groups extend them two ways — a party may
/// carry a group manifest + a considered flag, a ballot may carry member
/// attribution — and both extensions must stay optional so pre-group blobs
/// (and group-less parties) round-trip exactly as before.
void main() {
  Party party({String? groupId, bool considered = false}) => Party(
        id: 'p1',
        title: 'Where do we live?',
        options: const [
          PartyOption(id: 'a', label: 'The city'),
          PartyOption(id: 'b', label: 'The cabin'),
        ],
        votingMethod: VotingMethod.approval,
        createdAt: DateTime.utc(2026, 7, 11, 9),
        groupId: groupId,
        considered: considered,
      );

  group('party wire shape', () {
    test('a grouped, considered party round-trips manifest and flag', () {
      final json = PartyCodec.partyToJson(
        party(groupId: 'g1', considered: true),
        group: (id: 'g1', name: 'The household'),
      );

      expect(json['group'], {'id': 'g1', 'name': 'The household'});
      expect(json['considered'], isTrue);

      final decoded = PartyCodec.partyFromJson(json);
      expect(decoded.groupId, 'g1');
      expect(decoded.considered, isTrue);

      final manifest = PartyCodec.groupManifestOf(json);
      expect(manifest, isNotNull);
      expect(manifest!.id, 'g1');
      expect(manifest.name, 'The household');
    });

    test('legacy party json (no group/considered keys) decodes as ungrouped',
        () {
      // A blob written before persistent groups existed.
      final legacy = {
        'id': 'p1',
        'title': 'Dinner?',
        'votingMethod': 'approval',
        'options': [
          {'id': 'a', 'label': 'Tacos'},
          {'id': 'b', 'label': 'Sushi'},
        ],
        'createdAt': '2026-07-11T09:00:00.000Z',
        'closed': false,
      };

      final decoded = PartyCodec.partyFromJson(legacy);
      expect(decoded.groupId, isNull);
      expect(decoded.considered, isFalse);
      expect(PartyCodec.groupManifestOf(legacy), isNull);
    });

    test('the group field is driven only by the manifest argument', () {
      // Encoding a grouped party without passing the manifest emits no group
      // key at all — the codec never invents a manifest it wasn't given.
      final json = PartyCodec.partyToJson(party(groupId: 'g1'));
      expect(json.containsKey('group'), isFalse);
    });

    test(
        'an id-only group manifest decodes as ungrouped — never a dangling '
        'foreign key', () {
      // Joining only creates a group from a FULL manifest (id + name), so a
      // party that adopted the id alone would insert a parties row whose
      // group_id references a group that was never created.
      final json = PartyCodec.partyToJson(party());
      json['group'] = {'id': 'g-orphan'};

      expect(PartyCodec.groupManifestOf(json), isNull);
      expect(PartyCodec.partyFromJson(json).groupId, isNull,
          reason: 'the party must adopt a group only when the manifest the '
              'joiner uses to create it exists too');
    });
  });

  group('ballot wire shape', () {
    test('an attributed ballot round-trips member id and display name', () {
      final b = Ballot.approval(
        id: 'v1',
        party: party(),
        approvedOptionIds: const ['b'],
        memberId: 'm-1',
      );

      final json = PartyCodec.ballotToJson(b, memberDisplayName: 'Ada');
      expect(json['member'], {'id': 'm-1', 'displayName': 'Ada'});

      final decoded = PartyCodec.ballotFromJson(json, party());
      expect(decoded.memberId, 'm-1');

      final member = PartyCodec.memberOf(json);
      expect(member, isNotNull);
      expect(member!.id, 'm-1');
      expect(member.displayName, 'Ada');
    });

    test('an anonymous ballot stays anonymous on the wire', () {
      final b = Ballot.approval(
        id: 'v1',
        party: party(),
        approvedOptionIds: const ['a'],
      );

      final json = PartyCodec.ballotToJson(b);
      expect(json.containsKey('member'), isFalse);

      final decoded = PartyCodec.ballotFromJson(json, party());
      expect(decoded.memberId, isNull);
      expect(PartyCodec.memberOf(json), isNull);
    });

    test('legacy ballot json (no member key) decodes as anonymous', () {
      final legacy = {
        'id': 'v9',
        'method': 'approval',
        'approvals': ['a'],
        'ranking': <String>[],
      };
      final decoded = PartyCodec.ballotFromJson(legacy, party());
      expect(decoded.memberId, isNull);
    });

    test('attribution without a known display name still carries the id', () {
      final b = Ballot.approval(
        id: 'v1',
        party: party(),
        approvedOptionIds: const ['b'],
        memberId: 'm-2',
      );

      final json = PartyCodec.ballotToJson(b);
      expect(json['member'], {'id': 'm-2'});

      final member = PartyCodec.memberOf(json);
      expect(member!.id, 'm-2');
      expect(member.displayName, isNull);
    });
  });
}
