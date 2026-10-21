1. Edit button (title / uom / harga supplier / kategori)
   - DONE. Detail screen > "Ubah produk" (pencil icon in the top bar). A changed supplier price is saved as a new price history entry, and retail is recalculated unless it is a manual price.
2. Mass Edit button on screen (uom / kategori)
   - DONE. Product list > "Ubah massal" (checklist icon), or long-press a product. Pick products, then "Ubah yang dipilih" > satuan or kategori. Products that already have the value, and deleted products, are skipped.
3. Ketika impor, kalau nama sesuai atau bisa dimapping dengan yang ada di local storage, bisa mapping harga ke situ secara default (walau tetap highlight merah)
   - DONE (Review screen). If a line matches a product and its price is unreadable, the price defaults to what the same supplier last charged and stays highlighted. A default you did not check is not saved as a new price entry. A low-confidence price is kept as read, with the previous price shown.
4. Archive should be considered 'deleted' in user experience, even though it actually implemented as soft delete (archive) behavior
   - DONE. "Hapus produk" with an "Urungkan" snackbar for 6 seconds. Still a soft delete underneath. The archive screen and permanent delete are removed.
5. Pengecekan margin untuk harga jual bukan dari harga supplier tertinggi, tapi dari harga PO supplier terakhir. Bisa dibuat settings untuk average dari harga PO terakhir
   - DONE. Pengaturan > Batas margin > "Harga supplier untuk cek margin": PO terakhir (default) or Rata-rata N PO terakhir (N 2 to 20, default 3). Retail price calculation is unchanged. Schema version 2.
6. Impor belum otomatis mengkategorisasikan dengan etalase yg ada (ML based). Bisa diedit di impor page nya tersebut
   - DONE (Review screen). New products get a suggested category from the most similar products already filed (on-device nearest neighbours, no data leaves the phone). Shown as "(saran)" until you confirm it. Row menu > "Ubah kategori".
