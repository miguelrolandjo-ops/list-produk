import 'package:flutter_application_1/team/owner_account_service.dart';
import 'package:flutter_application_1/welcome/invite_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = 'https://miguelrolandjo-ops.github.io/j/';

  group('forCode', () {
    test('builds the link, with or without a trailing slash', () {
      expect(
        InviteLink.forCode('7kq2m9xa', base: base),
        'https://miguelrolandjo-ops.github.io/j/?kode=7KQ2M9XA',
      );
      expect(
        InviteLink.forCode('7KQ2M9XA', base: 'https://contoh.id/j'),
        'https://contoh.id/j/?kode=7KQ2M9XA',
      );
    });

    test('no base configured: no link', () {
      expect(InviteLink.forCode('7KQ2M9XA', base: ''), isNull);
      expect(InviteLink.forCode('7KQ2M9XA', base: '  '), isNull);
    });

    test('round trip', () {
      final link = InviteLink.forCode('ab12cd34', base: base)!;
      expect(InviteLink.codeFrom(link), 'AB12CD34');
    });
  });

  group('codeFrom', () {
    test('the https link in its forms', () {
      for (final link in [
        'https://miguelrolandjo-ops.github.io/j/?kode=7KQ2M9XA',
        'https://miguelrolandjo-ops.github.io/j?kode=7kq2m9xa',
        'https://contoh.id/j/7KQ2M9XA',
        '  https://contoh.id/j/?kode=7KQ2-M9XA  ',
      ]) {
        expect(InviteLink.codeFrom(link), '7KQ2M9XA', reason: link);
      }
    });

    test('the landing page button link', () {
      expect(InviteLink.codeFrom('hargatoko://join?kode=7KQ2M9XA'), '7KQ2M9XA');
      expect(InviteLink.codeFrom('hargatoko://join/7KQ2M9XA'), '7KQ2M9XA');
    });

    test('anything else is not an invite', () {
      for (final link in [
        'https://contoh.id/?kode=7KQ2M9XA', // not under /j
        'https://contoh.id/j/?kode=7KQ2', // too short
        'https://contoh.id/j/', // no code
        'hargatoko://lain?kode=7KQ2M9XA', // other host
        // Supabase login callbacks use "code": never taken as an invite.
        'hargatoko://login?code=7KQ2M9XA',
        'tidak ada tautan',
      ]) {
        expect(InviteLink.codeFrom(link), isNull, reason: link);
      }
    });
  });

  group('invite message', () {
    test('with a link: link first, code as the fallback', () {
      final m = TeamService.inviteMessage(
        '7KQ2M9XA',
        storeName: 'Toko Berkah',
        link: '$base?kode=7KQ2M9XA',
      );
      expect(m, contains('Toko Berkah'));
      expect(m, contains('$base?kode=7KQ2M9XA'));
      expect(m, contains('kode: 7KQ2M9XA'));
      expect(m.indexOf('https://'), lessThan(m.indexOf('kode: 7KQ2M9XA')));
    });

    test('without a link: the code only', () {
      final m = TeamService.inviteMessage('7KQ2M9XA');
      expect(m, isNot(contains('https://')));
      expect(m, contains('Kode undangan: 7KQ2M9XA'));
    });
  });
}
