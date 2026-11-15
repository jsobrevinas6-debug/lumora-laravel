import './bootstrap';

import Alpine from 'alpinejs';
import { gsap } from 'gsap';

window.Alpine = Alpine;
window.gsap = gsap;

Alpine.start();

function initFlowingMenu() {
    const items = document.querySelectorAll('[data-flowing-item]');
    if (!items.length || window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    items.forEach((item) => {
        const marquee = item.querySelector('[data-flowing-marquee]');
        const inner = item.querySelector('[data-flowing-marquee-inner]');
        const firstPart = inner?.querySelector('.flowing-marquee-part');

        if (!marquee || !inner || !firstPart) return;

        let loop;

        const startMarquee = () => {
            const width = firstPart.offsetWidth;
            if (!width) return;

            loop?.kill();
            loop = gsap.to(inner, {
                x: -width,
                duration: 15,
                ease: 'none',
                repeat: -1,
            });
        };

        const reveal = (event) => {
            const bounds = item.getBoundingClientRect();
            const fromTop = event.clientY < bounds.top + bounds.height / 2;

            gsap.killTweensOf([marquee, inner]);
            gsap.set(marquee, { y: fromTop ? '-101%' : '101%' });
            gsap.set(inner, { y: fromTop ? '101%' : '-101%' });
            gsap.to([marquee, inner], {
                y: 0,
                duration: 0.62,
                ease: 'power3.out',
                overwrite: true,
            });
        };

        const hide = (event) => {
            const bounds = item.getBoundingClientRect();
            const towardTop = event.clientY < bounds.top + bounds.height / 2;

            gsap.to(marquee, {
                y: towardTop ? '-101%' : '101%',
                duration: 0.55,
                ease: 'power3.inOut',
                overwrite: true,
            });
            gsap.to(inner, {
                y: towardTop ? '101%' : '-101%',
                duration: 0.55,
                ease: 'power3.inOut',
                overwrite: true,
            });
        };

        item.addEventListener('mouseenter', reveal);
        item.addEventListener('mouseleave', hide);
        startMarquee();

        const resizeObserver = new ResizeObserver(startMarquee);
        resizeObserver.observe(firstPart);
        item._flowingCleanup = () => {
            loop?.kill();
            resizeObserver.disconnect();
            item.removeEventListener('mouseenter', reveal);
            item.removeEventListener('mouseleave', hide);
        };
    });
}

function initFlowMenuInteractions() {
    if (window.__lumoraFlowMenuBound) return;
    window.__lumoraFlowMenuBound = true;

    const drawer = document.getElementById('flowMenuDrawer');
    const backdrop = document.getElementById('flowMenuBackdrop');
    const close = document.getElementById('flowMenuClose');
    const triggers = document.querySelectorAll('#flowMenuTrigger, #flowMenuTriggerLeft');

    if (!drawer || !backdrop) return;

    const setOpen = (open) => {
        drawer.classList.toggle('open', open);
        backdrop.classList.toggle('open', open);
        drawer.setAttribute('aria-hidden', open ? 'false' : 'true');
        triggers.forEach((trigger) => trigger.setAttribute('aria-expanded', open ? 'true' : 'false'));
        document.body.style.overflow = open ? 'hidden' : '';
    };

    triggers.forEach((trigger) => trigger.addEventListener('click', () => setOpen(!drawer.classList.contains('open'))));
    close?.addEventListener('click', () => setOpen(false));
    backdrop.addEventListener('click', () => setOpen(false));
    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') setOpen(false);
    });

    document.querySelectorAll('[data-submenu-toggle]').forEach((toggle) => {
        toggle.addEventListener('click', () => {
            const group = toggle.closest('[data-submenu-group]');
            const expanded = group.classList.toggle('open');
            toggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
        });
    });
}

function initAccountMenu() {
    const wrapper = document.getElementById('accountMenuWrap');
    const trigger = document.getElementById('accountTrigger');
    const menu = document.getElementById('accountDropdown');

    if (!wrapper || !trigger || !menu) return;

    const setOpen = (open) => {
        wrapper.classList.toggle('open', open);
        trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    };

    trigger.setAttribute('aria-haspopup', 'menu');
    trigger.addEventListener('click', () => setOpen(!wrapper.classList.contains('open')));

    document.addEventListener('click', (event) => {
        if (!wrapper.contains(event.target)) setOpen(false);
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape' && wrapper.classList.contains('open')) {
            setOpen(false);
            trigger.focus();
        }
    });

    menu.addEventListener('click', (event) => {
        if (event.target.closest('a[role="menuitem"]')) setOpen(false);
    });

    menu.addEventListener('submit', () => setOpen(false));
    window.addEventListener('pagehide', () => setOpen(false));
}

function initProfileNavigation() {
    const sidebar = document.querySelector('[data-profile-sidebar]');
    const backdrop = document.querySelector('[data-profile-backdrop]');
    const menuButton = document.querySelector('[data-profile-menu]');
    const drawerItems = Array.from(document.querySelectorAll('[data-profile-nav-item]'));
    const navItems = Array.from(document.querySelectorAll('[data-profile-nav-item][href^="#"]'));
    const sections = Array.from(document.querySelectorAll('[data-profile-section][id]'));

    if (!sidebar) return;

    const setDrawer = (open) => {
        sidebar.classList.toggle('open', open);
        backdrop?.classList.toggle('open', open);
        document.body.style.overflow = open ? 'hidden' : '';
    };

    const setActive = (id) => {
        const activeItem = navById.get(id);
        if (!activeItem) return;

        navItems.forEach((item) => {
            item.classList.remove('active');
            item.removeAttribute('aria-current');
        });

        activeItem.classList.add('active');
        activeItem.setAttribute('aria-current', 'page');
    };

    menuButton?.addEventListener('click', () => setDrawer(true));
    backdrop?.addEventListener('click', () => setDrawer(false));

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') setDrawer(false);
    });

    drawerItems.forEach((item) => {
        item.addEventListener('click', () => setDrawer(false));
    });

    window.addEventListener('resize', () => {
        if (window.innerWidth >= 768) setDrawer(false);
    });

    if (!navItems.length || !sections.length) return;

    const navById = new Map(
        navItems
            .map((item) => [item.getAttribute('href')?.slice(1), item])
            .filter(([id]) => Boolean(id)),
    );

    navItems.forEach((item) => {
        item.addEventListener('click', () => {
            const id = item.getAttribute('href')?.slice(1);
            if (id) setActive(id);
            setDrawer(false);
        });
    });

    const initialId = window.location.hash ? window.location.hash.slice(1) : sections[0]?.id;
    setActive(navById.has(initialId) ? initialId : sections[0].id);

    if (!('IntersectionObserver' in window)) return;

    const observer = new IntersectionObserver(
        (entries) => {
            const activeEntry = entries
                .filter((entry) => entry.isIntersecting)
                .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];

            if (activeEntry?.target?.id) {
                setActive(activeEntry.target.id);
            }
        },
        {
            threshold: 0.5,
            rootMargin: '-20% 0px -50% 0px',
        },
    );

    sections.forEach((section) => observer.observe(section));
}

function initWishlistInteractions() {
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content || '';
    let toastTimer;
    const updateWishlistCount = (count) => {
        document.querySelectorAll('[data-wishlist-count]').forEach((badge) => {
            badge.textContent = count;
            badge.hidden = Number(count) <= 0;
            badge.style.display = Number(count) > 0 ? '' : 'none';
        });
        const total = document.querySelector('[data-wishlist-total]');
        if (total) total.textContent = count;
    };
    const showToast = (message, undo = null) => {
        let toast = document.getElementById('wishlistToast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'wishlistToast';
            toast.className = 'wishlist-toast lumora-wishlist-toast';
            toast.setAttribute('role', 'status');
            toast.setAttribute('aria-live', 'polite');
            toast.innerHTML = '<span data-wishlist-toast-message></span><button type="button" data-wishlist-undo hidden>Undo</button>';
            document.body.appendChild(toast);
        }
        toast.querySelector('[data-wishlist-toast-message]').textContent = message;
        const undoButton = toast.querySelector('[data-wishlist-undo]');
        undoButton.hidden = !undo;
        undoButton.onclick = undo;
        toast.classList.add('is-visible');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 5000);
    };
    const request = async (url, method, body = null) => {
        const response = await fetch(url, {
            method,
            headers: {'X-CSRF-TOKEN': csrf, 'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json', ...(body ? {'Content-Type': 'application/json'} : {})},
            ...(body ? {body: JSON.stringify(body)} : {}),
        });
        const payload = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(payload.message || 'Could not update your wishlist.');
        return payload;
    };

    document.querySelectorAll('[data-wishlist-toggle]').forEach((button) => {
        button.addEventListener('click', async () => {
            if (button.dataset.auth !== '1') {
                window.location.href = button.dataset.loginUrl;
                return;
            }
            if (button.disabled) return;
            button.disabled = true;
            const wasSaved = button.dataset.saved === '1';
            try {
                const payload = wasSaved
                    ? await request(button.dataset.toggleUrl, 'POST')
                    : await request(button.dataset.addUrl, 'POST', {product_id: button.dataset.productId});
                button.dataset.saved = payload.saved ? '1' : '0';
                button.setAttribute('aria-pressed', payload.saved ? 'true' : 'false');
                button.setAttribute('aria-label', `${payload.saved ? 'Remove' : 'Add'} ${button.dataset.productName} ${payload.saved ? 'from' : 'to'} wishlist`);
                button.classList.toggle('is-saved', payload.saved);
                button.querySelector('svg')?.setAttribute('fill', payload.saved ? 'currentColor' : 'none');
                if (button.classList.contains('save-product-wishlist')) button.lastChild.textContent = payload.saved ? 'Saved to Wishlist' : 'Save to Wishlist';
                if (payload.count !== undefined) updateWishlistCount(payload.count);
                showToast(payload.message || (payload.saved ? 'Saved to your wishlist.' : 'Removed from your wishlist.'));
            } catch (error) {
                showToast(error.message);
            } finally {
                button.disabled = false;
            }
        });
    });

    document.querySelectorAll('[data-wishlist-remove]').forEach((button) => {
        button.addEventListener('click', async () => {
            const card = button.closest('[data-wishlist-card]');
            const productId = card?.dataset.productId;
            if (!productId || button.disabled) return;
            button.disabled = true;
            card.classList.add('is-removing');
            window.setTimeout(() => card.remove(), 220);
            try {
                const payload = await request(`/api/wishlist/${productId}`, 'DELETE');
                updateWishlistCount(payload.count);
                showToast('Removed from your wishlist.', async () => {
                    try {
                        await request('/api/wishlist', 'POST', {product_id: Number(productId)});
                        window.location.reload();
                    } catch (error) { showToast(error.message); }
                });
                if (!document.querySelector('[data-wishlist-card]')) {
                    document.getElementById('wishlistGrid')?.remove();
                    const empty = document.createElement('section');
                    empty.className = 'wishlist-empty';
                    const filtered = new URL(window.location.href).searchParams.has('shop') || new URL(window.location.href).searchParams.get('filter') !== null;
                    empty.innerHTML = filtered
                        ? '<h2>No items match these filters</h2><p>Try another filter or browse your full wishlist.</p><a class="wishlist-browse-button" href="/account/wishlist">Clear filters</a>'
                        : '<div class="wishlist-empty-heart" aria-hidden="true">♡</div><h2>Your wishlist is empty</h2><p>Tap the heart on any product to save it here.</p><a class="wishlist-browse-button" href="/shop">Browse products</a>';
                    document.querySelector('.wishlist-page .profile-content')?.appendChild(empty);
                }
            } catch (error) {
                window.location.reload();
            }
        });
    });

    const applyWishlistSelects = () => {
        const url = new URL(window.location.href);
        const sort = document.getElementById('wishlistSort')?.value || 'recent';
        const shop = document.getElementById('wishlistShop')?.value || '';
        if (sort === 'recent') url.searchParams.delete('sort'); else url.searchParams.set('sort', sort);
        if (shop) url.searchParams.set('shop', shop); else url.searchParams.delete('shop');
        document.getElementById('wishlistLoading')?.removeAttribute('hidden');
        document.getElementById('wishlistGrid')?.setAttribute('hidden', '');
        window.setTimeout(() => { window.location.href = url; }, 120);
    };
    document.getElementById('wishlistSort')?.addEventListener('change', applyWishlistSelects);
    document.getElementById('wishlistShop')?.addEventListener('change', applyWishlistSelects);
    document.querySelectorAll('.wishlist-filter').forEach((link) => link.addEventListener('click', (event) => {
        event.preventDefault();
        document.getElementById('wishlistLoading')?.removeAttribute('hidden');
        document.getElementById('wishlistGrid')?.setAttribute('hidden', '');
        window.setTimeout(() => { window.location.href = link.href; }, 120);
    }));
    document.querySelector('[data-wishlist-retry]')?.addEventListener('click', () => window.location.reload());

    document.querySelector('[data-wishlist-add-all]')?.addEventListener('click', async (event) => {
        const button = event.currentTarget;
        if (button.disabled) return;
        const items = Array.from(document.querySelectorAll('[data-wishlist-card]'))
            .map((card) => ({form: card.querySelector('.wishlist-cart-form'), name: card.querySelector('.wishlist-product-name')?.textContent.trim()}))
            .filter((item) => item.form);
        if (!items.length) return;
        button.disabled = true;
        let added = 0;
        let failed = 0;
        for (const item of items) {
            try {
                const response = await fetch(item.form.action, {
                    method: 'POST',
                    headers: {'X-Requested-With': 'XMLHttpRequest', 'Accept': 'application/json'},
                    body: new FormData(item.form),
                });
                const payload = await response.json().catch(() => ({}));
                if (!response.ok) throw new Error(payload.message || 'Unavailable');
                document.querySelectorAll('[data-cart-count]').forEach((badge) => {
                    badge.textContent = payload.cart_count ?? badge.textContent;
                    badge.hidden = Number(badge.textContent) <= 0;
                    badge.style.display = Number(badge.textContent) > 0 ? '' : 'none';
                });
                added++;
            } catch { failed++; }
        }
        showToast(failed ? `${added} added to cart; ${failed} could not be added.` : `${added} ${added === 1 ? 'item' : 'items'} added to cart.`);
        button.disabled = false;
    });
}

document.addEventListener('DOMContentLoaded', () => {
    initFlowMenuInteractions();
    initAccountMenu();
    initFlowingMenu();
    initProfileNavigation();
    initWishlistInteractions();
});
