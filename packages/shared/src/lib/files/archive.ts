export type FilesApiEntry = {
	name: string;
	url: string;
	extension?: string;
	mime_type?: string;
	size_bytes?: number;
	size_human?: string;
	modified_timestamp?: number;
	modified_iso?: string;
};

export type FilesApiResponse = {
	success: boolean;
	count?: number;
	files?: FilesApiEntry[];
	error?: string;
};

export type FileKind = 'image' | 'pdf' | 'text' | 'archive' | 'default';

export const FILES_SITE_ORIGIN = 'https://files.marianialessandro.com';

const DISPLAY_NAME_MAP: Record<string, string> = {
	'programAnalysisNotes.pdf': 'Program Analysis',
	'compilationTechniqueNotes.pdf': 'Compilation Techniques',
	'algorithmDesignNotes.pdf': 'Algorithm Design',
	'parallel.pdf': 'Parallel'
};

const IMAGE_EXTENSIONS = new Set(['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'avif']);
const PDF_EXTENSIONS = new Set(['pdf']);
const TEXT_EXTENSIONS = new Set(['txt', 'md', 'json', 'xml', 'csv', 'log', 'php', 'js', 'css', 'html']);
const ARCHIVE_EXTENSIONS = new Set(['zip', 'rar', '7z', 'tar', 'gz']);

export function getDisplayName(filename: string): string {
	if (DISPLAY_NAME_MAP[filename]) {
		return DISPLAY_NAME_MAP[filename];
	}

	const withoutExtension = filename.replace(/\.[^.]+$/, '');
	const normalized = withoutExtension.replace(/[-_]+/g, ' ').trim();

	if (!normalized) {
		return filename;
	}

	return normalized.replace(/\b\w/g, (char) => char.toUpperCase());
}

export function getExtensionLabel(filename: string): string {
	const extension = getExtension(filename);
	return extension ? extension.toUpperCase() : 'FILE';
}

export function getFileKind(filename: string): FileKind {
	const extension = getExtension(filename);

	if (IMAGE_EXTENSIONS.has(extension)) {
		return 'image';
	}

	if (PDF_EXTENSIONS.has(extension)) {
		return 'pdf';
	}

	if (TEXT_EXTENSIONS.has(extension)) {
		return 'text';
	}

	if (ARCHIVE_EXTENSIONS.has(extension)) {
		return 'archive';
	}

	return 'default';
}

export function formatBytes(bytes: number): string {
	if (bytes < 1024) {
		return `${bytes} B`;
	}

	const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
	let value = bytes / 1024;

	for (const unit of units) {
		if (value < 1024) {
			return `${new Intl.NumberFormat('it-IT', {
				maximumFractionDigits: value < 10 ? 1 : 0,
				minimumFractionDigits: value < 10 ? 1 : 0
			}).format(value)} ${unit}`;
		}

		value /= 1024;
	}

	return `${new Intl.NumberFormat('it-IT', {
		maximumFractionDigits: 1,
		minimumFractionDigits: 1
	}).format(value)} EB`;
}

export function formatDate(isoDate: string): string {
	const date = new Date(isoDate);

	if (Number.isNaN(date.getTime())) {
		return isoDate;
	}

	return new Intl.DateTimeFormat('it-IT', {
		day: '2-digit',
		month: '2-digit',
		year: 'numeric',
		hour: '2-digit',
		minute: '2-digit'
	}).format(date);
}

export function resolveFilesSiteUrl(url: string): string {
	if (!url) {
		return FILES_SITE_ORIGIN;
	}

	if (/^https?:\/\//i.test(url)) {
		return url;
	}

	return new URL(url, FILES_SITE_ORIGIN).toString();
}

function getExtension(filename: string): string {
	const parts = filename.toLowerCase().split('.');
	return parts.length > 1 ? parts.at(-1) ?? '' : '';
}
