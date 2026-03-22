/** @typedef {{ type?: string; value?: string; alt?: string; children?: RemarkNode[]; data?: { hProperties?: Record<string, string> } }} RemarkNode */

/** @param {string} value */
const slugify = (value) =>
	value
		.toLowerCase()
		.normalize('NFD')
		.replace(/\s*\(h[1-6]\)\s*$/i, '')
		.replace(/[\u0300-\u036f]/g, '')
		.replace(/[^a-z0-9\s-]/g, '')
		.trim()
		.replace(/\s+/g, '-')
		.replace(/-+/g, '-');

/** @param {RemarkNode | null | undefined} node @returns {string} */
const getNodeText = (node) => {
	if (!node || typeof node !== 'object') return '';

	if ('value' in node && typeof node.value === 'string') {
		return node.value;
	}

	if ('alt' in node && typeof node.alt === 'string') {
		return node.alt;
	}

	if ('children' in node && Array.isArray(node.children)) {
		return node.children.map(getNodeText).join('');
	}

	return '';
};

/** @param {RemarkNode | null | undefined} node @param {(node: RemarkNode) => void} callback @returns {void} */
const visit = (node, callback) => {
	if (!node || typeof node !== 'object') return;

	callback(node);

	if ('children' in node && Array.isArray(node.children)) {
		node.children.forEach((child) => visit(child, callback));
	}
};

/** @returns {(tree: RemarkNode) => void} */
export function remarkHeadingIds() {
	/** @param {RemarkNode} tree */
	return (tree) => {
		const seen = new Map();

		visit(tree, (node) => {
			if (node.type !== 'heading') return;

			const text = getNodeText(node).trim() || 'section';
			const base = slugify(text) || 'section';
			const count = (seen.get(base) ?? 0) + 1;

			seen.set(base, count);

			const id = count === 1 ? base : `${base}-${count}`;

			node.data ??= {};
			node.data.hProperties = {
				...(node.data.hProperties ?? {}),
				id
			};
		});
	};
}
