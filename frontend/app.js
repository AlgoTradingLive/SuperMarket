const API = "/api";
let allProducts = [];
let cart = JSON.parse(localStorage.getItem("cart") || "{}"); // { productId: qty }
let activeCategory = "All";

const productGrid = document.getElementById("productGrid");
const categoriesEl = document.getElementById("categories");
const cartCountEl = document.getElementById("cartCount");
const cartItemsEl = document.getElementById("cartItems");
const cartTotalEl = document.getElementById("cartTotal");
const searchInput = document.getElementById("searchInput");

// ---------- Load data ----------
async function loadCategories() {
  const res = await fetch(`${API}/products/categories`);
  const categories = await res.json();
  categoriesEl.innerHTML = categories
    .map(
      (c) =>
        `<button class="category-chip ${c === activeCategory ? "active" : ""}" data-cat="${c}">${c}</button>`
    )
    .join("");

  categoriesEl.querySelectorAll(".category-chip").forEach((btn) => {
    btn.addEventListener("click", () => {
      activeCategory = btn.dataset.cat;
      loadProducts();
      loadCategories();
    });
  });
}

async function loadProducts() {
  const params = new URLSearchParams();
  if (activeCategory !== "All") params.set("category", activeCategory);
  if (searchInput.value.trim()) params.set("search", searchInput.value.trim());

  const res = await fetch(`${API}/products?${params.toString()}`);
  allProducts = await res.json();
  renderProducts();
}

function renderProducts() {
  productGrid.innerHTML = allProducts
    .map((p) => {
      const qty = cart[p.id] || 0;
      return `
        <div class="product-card">
          <img src="${p.image}" alt="${p.name}" />
          <div class="product-name">${p.name}</div>
          <div class="product-unit">${p.unit}</div>
          <div>
            <span class="product-price">₹${p.price}</span>
            ${p.mrp > p.price ? `<span class="product-mrp">₹${p.mrp}</span>` : ""}
          </div>
          ${
            qty === 0
              ? `<button class="add-btn" data-id="${p.id}">ADD</button>`
              : `<div class="qty-control">
                  <button data-action="dec" data-id="${p.id}">−</button>
                  <span>${qty}</span>
                  <button data-action="inc" data-id="${p.id}">+</button>
                </div>`
          }
        </div>`;
    })
    .join("");

  productGrid.querySelectorAll(".add-btn").forEach((btn) =>
    btn.addEventListener("click", () => changeQty(Number(btn.dataset.id), 1))
  );
  productGrid.querySelectorAll("[data-action]").forEach((btn) =>
    btn.addEventListener("click", () =>
      changeQty(Number(btn.dataset.id), btn.dataset.action === "inc" ? 1 : -1)
    )
  );
}

// ---------- Cart logic ----------
function changeQty(id, delta) {
  const newQty = (cart[id] || 0) + delta;
  if (newQty <= 0) delete cart[id];
  else cart[id] = newQty;
  localStorage.setItem("cart", JSON.stringify(cart));
  renderProducts();
  renderCart();
}

function getCartItems() {
  return Object.entries(cart).map(([id, qty]) => {
    const product = allProducts.find((p) => p.id === Number(id)) ||
      { id: Number(id), name: "Product", price: 0 };
    return { ...product, qty };
  });
}

function cartTotal() {
  return getCartItems().reduce((sum, item) => sum + item.price * item.qty, 0);
}

function renderCart() {
  const totalQty = Object.values(cart).reduce((a, b) => a + b, 0);
  cartCountEl.textContent = totalQty;

  const items = getCartItems();
  if (items.length === 0) {
    cartItemsEl.innerHTML = `<p style="padding:20px;color:#888;">Your cart is empty</p>`;
  } else {
    cartItemsEl.innerHTML = items
      .map(
        (item) => `
      <div class="cart-item">
        <div class="cart-item-name">${item.name}<br/><small>₹${item.price} x ${item.qty}</small></div>
        <div class="cart-item-controls">
          <button data-action="dec" data-id="${item.id}">−</button>
          <span>${item.qty}</span>
          <button data-action="inc" data-id="${item.id}">+</button>
        </div>
      </div>`
      )
      .join("");
    cartItemsEl.querySelectorAll("[data-action]").forEach((btn) =>
      btn.addEventListener("click", () =>
        changeQty(Number(btn.dataset.id), btn.dataset.action === "inc" ? 1 : -1)
      )
    );
  }
  cartTotalEl.textContent = cartTotal();
}

// ---------- UI events ----------
document.getElementById("cartBtn").addEventListener("click", () => {
  document.getElementById("cartSidebar").classList.add("open");
  document.getElementById("cartOverlay").classList.add("open");
});
function closeCartSidebar() {
  document.getElementById("cartSidebar").classList.remove("open");
  document.getElementById("cartOverlay").classList.remove("open");
}
document.getElementById("closeCart").addEventListener("click", closeCartSidebar);
document.getElementById("cartOverlay").addEventListener("click", closeCartSidebar);

let searchTimer;
searchInput.addEventListener("input", () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(loadProducts, 300);
});

// ---------- Checkout ----------
const checkoutOverlay = document.getElementById("checkoutOverlay");
document.getElementById("checkoutBtn").addEventListener("click", () => {
  if (cartTotal() === 0) return alert("Cart is empty!");
  document.getElementById("modalTotal").textContent = cartTotal();
  checkoutOverlay.classList.add("open");
});
document.getElementById("cancelCheckout").addEventListener("click", () => {
  checkoutOverlay.classList.remove("open");
});

document.getElementById("placeOrderBtn").addEventListener("click", async () => {
  const customerName = document.getElementById("custName").value.trim();
  const phone = document.getElementById("custPhone").value.trim();
  const address = document.getElementById("custAddress").value.trim();

  if (!customerName || !phone || !address) {
    alert("कृपया सर्व माहिती भरा");
    return;
  }

  const items = getCartItems();
  const res = await fetch(`${API}/orders`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ items, customerName, phone, address }),
  });
  const data = await res.json();

  if (res.ok) {
    cart = {};
    localStorage.setItem("cart", "{}");
    renderCart();
    renderProducts();
    checkoutOverlay.classList.remove("open");
    closeCartSidebar();
    document.getElementById(
      "successMsg"
    ).textContent = `Order #${data.order.id} confirmed for ₹${data.order.total}. Pay on delivery.`;
    document.getElementById("successOverlay").classList.add("open");
  } else {
    alert(data.error || "Something went wrong");
  }
});
document.getElementById("closeSuccess").addEventListener("click", () => {
  document.getElementById("successOverlay").classList.remove("open");
});

// ---------- Init ----------
(async function init() {
  await loadCategories();
  await loadProducts();
  renderCart();
})();
