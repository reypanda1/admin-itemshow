const DOM = {
    app: document.getElementById('app'),
    itemsGrid: document.getElementById('itemsGrid'),
    searchInput: document.getElementById('searchInput'),
    closeBtn: document.getElementById('closeBtn'),
    itemsCount: document.getElementById('itemsCount'),
    noResults: document.getElementById('noResults'),
    quantityModal: document.getElementById('quantityModal'),
    quantityInput: document.getElementById('quantityInput'),
    decreaseBtn: document.getElementById('decreaseBtn'),
    increaseBtn: document.getElementById('increaseBtn'),
    confirmBtn: document.getElementById('confirmBtn'),
    cancelBtn: document.getElementById('cancelBtn'),
    modalCloseBtn: document.getElementById('modalCloseBtn'),
    modalItemName: document.getElementById('modalItemName'),
    notification: document.getElementById('notification')
};

let allItems = [];
let filteredItems = [];
let itemsMap = new Map();
let isMenuOpen = false;
let selectedItemName = null;
let selectedItemUnique = false;
const resourceName = 'Visualisador de items';
const encodedResourceName = encodeURIComponent(resourceName);

const escapeHtml = (text) => {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
};

const renderItems = () => {
    const len = filteredItems.length;
    const items = filteredItems;
    
    if (len === 0) {
        DOM.noResults.classList.remove('hidden');
        DOM.itemsCount.textContent = '0';
        DOM.itemsGrid.innerHTML = '';
        return;
    }
    
    DOM.noResults.classList.add('hidden');
    DOM.itemsCount.textContent = len;
    
    const html = new Array(len);
    for (let i = 0; i < len; i++) {
        const item = items[i];
        const isUnique = item.unique === true;
        const badge = isUnique ? '<span class="item-badge">ÚNICO</span>' : '';
        const hasImage = item.image && item.image !== 'default.png';
        const img = hasImage ? `<img src="nui://qb-inventory/html/images/${item.image}" class="item-image" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">` : '';
        const placeholder = hasImage ? '<div class="item-image-placeholder" style="display:none">📦</div>' : '<div class="item-image-placeholder">📦</div>';
        const label = escapeHtml(item.label);
        const name = escapeHtml(item.name);
        
        html[i] = `<div class="item-card" data-name="${name}"${isUnique ? ' data-unique="1"' : ''}>${badge}${img}${placeholder}<div class="item-label">${label}</div><div class="item-name">${name}</div></div>`;
    }
    
    DOM.itemsGrid.innerHTML = html.join('');
};

DOM.itemsGrid.addEventListener('click', (e) => {
    const card = e.target.closest('.item-card');
    if (!card) return;
    
    const itemName = card.dataset.name;
    const isUnique = card.dataset.unique === '1';
    
    if (isUnique) {
        pickupItem(itemName, 1);
    } else {
        const item = itemsMap.get(itemName);
        if (item) showQuantityModal(item);
    }
});

DOM.searchInput.addEventListener('input', (e) => {
    const term = e.target.value.toLowerCase().trim();
    const items = allItems;
    const itemsLen = items.length;
    
    if (!term) {
        filteredItems = items;
    } else {
        filteredItems = [];
        for (let i = 0; i < itemsLen; i++) {
            const item = items[i];
            if (item.name.toLowerCase().includes(term) || item.label.toLowerCase().includes(term)) {
                filteredItems.push(item);
            }
        }
    }
    
    renderItems();
});

const showMenu = () => {
    DOM.app.classList.remove('hidden');
    isMenuOpen = true;
    DOM.searchInput.focus();
};

const hideMenu = () => {
    DOM.app.classList.add('hidden');
    isMenuOpen = false;
    DOM.searchInput.value = '';
    allItems = [];
    filteredItems = [];
    DOM.itemsGrid.innerHTML = '';
};

const showQuantityModal = (item) => {
    selectedItemName = item.name;
    selectedItemUnique = item.unique === true;
    
    DOM.modalItemName.textContent = `Cantidad: ${escapeHtml(item.label)}`;
    DOM.quantityInput.value = 1;
    
    if (selectedItemUnique) {
        DOM.quantityInput.max = 1;
        DOM.quantityInput.readOnly = true;
        DOM.increaseBtn.disabled = true;
        DOM.decreaseBtn.disabled = true;
        DOM.quantityInput.style.cssText = 'cursor:not-allowed;opacity:0.7';
    } else {
        DOM.quantityInput.max = 9999;
        DOM.quantityInput.readOnly = false;
        DOM.increaseBtn.disabled = false;
        DOM.decreaseBtn.disabled = false;
        DOM.quantityInput.style.cssText = 'cursor:text;opacity:1';
    }
    
    DOM.quantityModal.classList.remove('hidden');
    if (!selectedItemUnique) {
        DOM.quantityInput.focus();
        DOM.quantityInput.select();
    }
};

const hideQuantityModal = () => {
    DOM.quantityModal.classList.add('hidden');
    selectedItemName = null;
    selectedItemUnique = false;
    DOM.quantityInput.readOnly = false;
    DOM.quantityInput.max = 9999;
    DOM.increaseBtn.disabled = false;
    DOM.decreaseBtn.disabled = false;
    DOM.quantityInput.style.cssText = 'cursor:text;opacity:1';
};

const pickupItem = async (itemName, quantity) => {
    const qty = Math.max(1, parseInt(quantity) || 1);
    
    try {
        await fetch(`https://${encodedResourceName}/pickup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ itemName, quantity: qty })
        });
        hideQuantityModal();
    } catch (e) {
        console.error('Error:', e);
    }
};

const closeMenu = async () => {
    try {
        await fetch(`https://${encodedResourceName}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    } catch (e) {}
    hideMenu();
};

const showNotification = (type, message) => {
    const notification = DOM.notification;
    notification.textContent = message;
    notification.className = 'notification';
    
    if (type === 'success') {
        notification.classList.add('notification-success');
    } else if (type === 'error') {
        notification.classList.add('notification-error');
    }
    
    notification.classList.remove('hidden');
    
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 4000);
};

window.addEventListener('message', (e) => {
    const { action, items, type, message } = e.data;
    if (action === 'setItems') {
        allItems = items || [];
        filteredItems = allItems;
        itemsMap.clear();
        for (let i = 0; i < allItems.length; i++) {
            itemsMap.set(allItems[i].name, allItems[i]);
        }
        renderItems();
        showMenu();
    } else if (action === 'close') {
        hideMenu();
    } else if (action === 'notify') {
        showNotification(type, message);
    }
});

DOM.closeBtn.addEventListener('click', closeMenu);

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (!DOM.quantityModal.classList.contains('hidden')) {
            hideQuantityModal();
        } else if (isMenuOpen) {
            closeMenu();
        }
    }
});

DOM.decreaseBtn.addEventListener('click', () => {
    const val = (parseInt(DOM.quantityInput.value) || 1) - 1;
    DOM.quantityInput.value = val > 1 ? val : 1;
});

DOM.increaseBtn.addEventListener('click', () => {
    const max = selectedItemUnique ? 1 : 9999;
    const val = (parseInt(DOM.quantityInput.value) || 1) + 1;
    DOM.quantityInput.value = val < max ? val : max;
});

DOM.quantityInput.addEventListener('input', (e) => {
    const min = 1;
    const max = selectedItemUnique ? 1 : 9999;
    let val = parseInt(e.target.value) || 1;
    if (val < min) val = min;
    if (val > max) val = max;
    e.target.value = val;
});

DOM.quantityInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') DOM.confirmBtn.click();
});

DOM.confirmBtn.addEventListener('click', () => {
    if (selectedItemName) {
        const qty = selectedItemUnique ? 1 : (parseInt(DOM.quantityInput.value) || 1);
        pickupItem(selectedItemName, qty);
    }
});

DOM.cancelBtn.addEventListener('click', hideQuantityModal);
DOM.modalCloseBtn.addEventListener('click', hideQuantityModal);

DOM.quantityModal.addEventListener('click', (e) => {
    if (e.target === DOM.quantityModal) hideQuantityModal();
});

hideMenu();
