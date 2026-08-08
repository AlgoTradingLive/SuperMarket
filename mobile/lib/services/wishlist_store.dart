// संपूर्ण app मध्ये wishlist state शेअर करण्यासाठी साधा store.
// सध्या फक्त session पुरता (app बंद केल्यावर रीसेट होतो) — नंतर backend ला जोडता येईल.
class WishlistStore {
  static final Set<int> _ids = {};

  static bool isWishlisted(int productId) => _ids.contains(productId);

  static void toggle(int productId) {
    if (_ids.contains(productId)) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
  }
}
