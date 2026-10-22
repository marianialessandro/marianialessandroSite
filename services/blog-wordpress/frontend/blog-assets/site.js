document.querySelectorAll('.filter-bar select').forEach((select) => {
	select.addEventListener('change', () => select.form.requestSubmit());
});

const links = [...document.querySelectorAll('.portfolio-toc a.link')];
if ('IntersectionObserver' in window && links.length) {
	const observer = new IntersectionObserver((entries) => {
		for (const entry of entries) {
			if (!entry.isIntersecting) continue;
			for (const link of links) {
				const active = link.hash.slice(1) === entry.target.id;
				link.parentElement.classList.toggle('active', active);
				if (active) link.setAttribute('aria-current', 'true');
				else link.removeAttribute('aria-current');
			}
		}
	}, { rootMargin: '0px 0px -70% 0px', threshold: 0.1 });
	for (const link of links) {
		const heading = document.getElementById(link.hash.slice(1));
		if (heading) observer.observe(heading);
	}
}
