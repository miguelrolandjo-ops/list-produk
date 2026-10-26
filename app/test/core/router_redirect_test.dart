import 'package:flutter_application_1/core/app_mode.dart';
import 'package:flutter_application_1/core/app_shell.dart';
import 'package:flutter_application_1/core/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no mode yet: only the welcome and onboarding screens', () {
    expect(redirectFor(null, '/'), '/mulai');
    expect(redirectFor(null, '/karyawan'), '/mulai');
    expect(redirectFor(null, '/mulai'), isNull);
    expect(redirectFor(null, '/mulai/toko'), isNull);
  });

  test('employee phones can never open an owner screen', () {
    for (final path in [
      '/',
      '/produk',
      '/produk/abc',
      '/pengaturan',
      '/pengaturan/cadangan',
      '/supplier',
      '/tim',
      '/mulai',
    ]) {
      expect(redirectFor(AppMode.employee, path), '/karyawan', reason: path);
    }
    expect(redirectFor(AppMode.employee, '/karyawan/daftar'), isNull);
  });

  test('the owner never sees welcome or employee screens', () {
    expect(redirectFor(AppMode.owner, '/mulai'), '/');
    expect(redirectFor(AppMode.owner, '/karyawan'), '/');
    expect(redirectFor(AppMode.owner, '/produk/abc'), isNull);
  });

  test('shell sections', () {
    expect(OwnerShell.sectionOf('/'), '/');
    expect(OwnerShell.sectionOf('/kategori/x'), '/');
    expect(OwnerShell.sectionOf('/produk/abc/ubah'), '/');
    expect(OwnerShell.sectionOf('/pengaturan/akun'), '/pengaturan');
    expect(OwnerShell.sectionOf('/pengaturan/cadangan'), '/pengaturan/cadangan');
    expect(OwnerShell.sectionOf('/tim'), '/tim');
    expect(OwnerShell.sectionOf('/inbox'), '/inbox');
    expect(OwnerShell.sectionOf('/po/abc/review'), '/inbox');
  });
}
