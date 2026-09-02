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

document.addEventListener('DOMContentLoaded', () => {
    initFlowMenuInteractions();
    initFlowingMenu();
});
