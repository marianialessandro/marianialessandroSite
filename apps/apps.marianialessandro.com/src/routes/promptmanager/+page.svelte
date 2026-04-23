<script lang="ts">
	import { onMount, tick } from 'svelte';
	import { loadPromptManagerState, savePromptManagerState } from '$lib/promptmanager/storage';
	import type {
		PromptDocument,
		PromptFolder,
		PromptManagerState
	} from '$lib/promptmanager/types';

	type NameModalState =
		| {
				kind: 'create-root-folder';
				value: string;
		  }
		| {
				kind: 'create-child-folder';
				parentId: string;
				value: string;
		  }
		| {
				kind: 'rename-folder';
				folderId: string;
				value: string;
		  }
		| {
				kind: 'rename-prompt';
				promptId: string;
				value: string;
		  };

	type NewPromptModalState = {
		folderId: string;
		title: string;
		content: string;
	};

	type DeleteDialogState =
		| {
				kind: 'folder';
				folderId: string;
				name: string;
		  }
		| {
				kind: 'prompt';
				promptId: string;
				name: string;
		  };

	type ContextMenuState =
		| {
				kind: 'root';
				x: number;
				y: number;
		  }
		| {
				kind: 'folder';
				x: number;
				y: number;
				folderId: string;
		  }
		| {
				kind: 'prompt';
				x: number;
				y: number;
				promptId: string;
		  };

	type DragPayload =
		| {
				kind: 'folder';
				id: string;
		  }
		| {
				kind: 'prompt';
				id: string;
		  };

	type InfoDialogState = {
		status: 'loading' | 'ready';
		promptId: string;
	};

	type ExplorerRow =
		| {
				kind: 'folder';
				folder: PromptFolder;
				depth: number;
				hasChildren: boolean;
				isExpanded: boolean;
		  }
		| {
				kind: 'prompt';
				prompt: PromptDocument;
				depth: number;
		  };

	type PromptManagerExportPayload = {
		app: 'apps.marianialessandro.com/promptmanager';
		version: 1;
		exportedAt: string;
		data: PromptManagerState;
	};

	const AUTOSAVE_DELAY_MS = 700;

	let folders = $state<PromptFolder[]>([]);
	let prompts = $state<PromptDocument[]>([]);
	let expandedFolderIds = $state<string[]>([]);
	let selectedFolderId = $state<string | null>(null);
	let selectedPromptId = $state<string | null>(null);
	let editingPromptId = $state<string | null>(null);
	let editingTitle = $state('');
	let editingContent = $state('');
	let editSessionSnapshot = $state<PromptDocument | null>(null);
	let nameModal = $state<NameModalState | null>(null);
	let newPromptModal = $state<NewPromptModalState | null>(null);
	let deleteDialog = $state<DeleteDialogState | null>(null);
	let contextMenu = $state<ContextMenuState | null>(null);
	let infoDialog = $state<InfoDialogState | null>(null);
	let settingsOpen = $state(false);
	let dragging = $state<DragPayload | null>(null);
	let dropTargetFolderId = $state<string | null>(null);
	let rootDropActive = $state(false);
	let copiedPromptId = $state<string | null>(null);
	let isReady = $state(false);
	let didLoadFail = $state(false);
	let importExportMessage = $state<string | null>(null);
	let importExportError = $state<string | null>(null);
	let isImporting = $state(false);
	let importFileInput = $state<HTMLInputElement | null>(null);

	let nameInput = $state<HTMLInputElement | null>(null);
	let topbarTitleInput = $state<HTMLInputElement | null>(null);
	let promptTitleInput = $state<HTMLInputElement | null>(null);
	let promptContentInput = $state<HTMLTextAreaElement | null>(null);
	let editorTextarea = $state<HTMLTextAreaElement | null>(null);

	let autosaveTimer = 0;
	let copyFeedbackTimer = 0;
	let persistQueue: Promise<void> = Promise.resolve();

	onMount(() => {
		let isCancelled = false;

		void (async () => {
			try {
				const state = await loadPromptManagerState();

				if (isCancelled) {
					return;
				}

				folders = state.folders;
				prompts = state.prompts;
				expandedFolderIds = getInitialExpandedFolderIds(state.folders, state.prompts);
				selectedFolderId = state.folders[0]?.id ?? null;
			} catch (error) {
				console.error(error);
				didLoadFail = true;
			} finally {
				if (!isCancelled) {
					isReady = true;
				}
			}
		})();

		const handleWindowClick = (event: MouseEvent) => {
			const target = event.target as HTMLElement | null;

			if (contextMenu && !target?.closest('.context-menu')) {
				contextMenu = null;
			}
		};

		const handleWindowKeydown = (event: KeyboardEvent) => {
			if (event.key !== 'Escape') {
				return;
			}

			if (contextMenu) {
				contextMenu = null;
				return;
			}

			if (nameModal || newPromptModal || deleteDialog) {
				closeTransientPanels();
				return;
			}

			if (infoDialog) {
				infoDialog = null;
				return;
			}

			if (settingsOpen) {
				settingsOpen = false;
				return;
			}

			if (editingPromptId) {
				event.preventDefault();
				void cancelEditing();
				return;
			}

			if (selectedPromptId) {
				selectedPromptId = null;
			}
		};

		window.addEventListener('click', handleWindowClick, true);
		window.addEventListener('keydown', handleWindowKeydown);

		return () => {
			isCancelled = true;
			clearAutosaveTimer();
			clearCopyFeedbackTimer();
			window.removeEventListener('click', handleWindowClick, true);
			window.removeEventListener('keydown', handleWindowKeydown);
		};
	});

	function compareLabels(left: string, right: string): number {
		return left.localeCompare(right, 'it', { sensitivity: 'base' });
	}

	function normalizeLabel(value: string): string {
		return value.trim();
	}

	function sortFolders(items: PromptFolder[]): PromptFolder[] {
		return [...items].sort((left, right) => {
			const byName = compareLabels(left.name, right.name);
			return byName !== 0 ? byName : left.id.localeCompare(right.id);
		});
	}

	function sortPrompts(items: PromptDocument[]): PromptDocument[] {
		return [...items].sort((left, right) => {
			const byTitle = compareLabels(left.title, right.title);
			return byTitle !== 0 ? byTitle : left.id.localeCompare(right.id);
		});
	}

	function getFolderById(folderId: string | null): PromptFolder | undefined {
		if (!folderId) {
			return undefined;
		}

		return folders.find((folder) => folder.id === folderId);
	}

	function getPromptById(promptId: string | null): PromptDocument | undefined {
		if (!promptId) {
			return undefined;
		}

		return prompts.find((prompt) => prompt.id === promptId);
	}

	function getChildFolders(parentId: string | null): PromptFolder[] {
		return sortFolders(folders.filter((folder) => folder.parentId === parentId));
	}

	function getFolderPrompts(folderId: string): PromptDocument[] {
		return sortPrompts(prompts.filter((prompt) => prompt.folderId === folderId));
	}

	function getFolderChildrenCount(folderId: string): number {
		return folders.filter((folder) => folder.parentId === folderId).length +
			prompts.filter((prompt) => prompt.folderId === folderId).length;
	}

	function folderHasDescendants(folderId: string): boolean {
		const directChildren = getFolderChildrenCount(folderId);

		if (directChildren > 0) {
			return true;
		}

		return getChildFolders(folderId).some((folder) => folderHasDescendants(folder.id));
	}

	function getInitialExpandedFolderIds(
		initialFolders: PromptFolder[],
		initialPrompts: PromptDocument[]
	): string[] {
		const hasContentInTree = (folderId: string): boolean => {
			const hasDirectPrompts = initialPrompts.some((prompt) => prompt.folderId === folderId);
			const children = initialFolders.filter((folder) => folder.parentId === folderId);

			if (hasDirectPrompts || children.length > 0) {
				return true;
			}

			return children.some((folder) => hasContentInTree(folder.id));
		};

		return initialFolders
			.filter((folder) => folder.parentId === null && hasContentInTree(folder.id))
			.map((folder) => folder.id);
	}

	function getFolderAncestors(folderId: string | null): string[] {
		const ancestors: string[] = [];
		let currentFolder = getFolderById(folderId ?? null);

		while (currentFolder?.parentId) {
			ancestors.push(currentFolder.parentId);
			currentFolder = getFolderById(currentFolder.parentId);
		}

		return ancestors;
	}

	function ensureExpanded(folderId: string): void {
		const next = new Set(expandedFolderIds);

		next.add(folderId);

		for (const ancestorId of getFolderAncestors(folderId)) {
			next.add(ancestorId);
		}

		expandedFolderIds = [...next];
	}

	function toggleExpanded(folderId: string): void {
		if (expandedFolderIds.includes(folderId)) {
			expandedFolderIds = expandedFolderIds.filter((id) => id !== folderId);
			return;
		}

		ensureExpanded(folderId);
	}

	function getExplorerRows(parentId: string | null = null, depth = 0): ExplorerRow[] {
		const rows: ExplorerRow[] = [];

		for (const folder of getChildFolders(parentId)) {
			const hasChildren = getFolderChildrenCount(folder.id) > 0;
			const isExpanded = expandedFolderIds.includes(folder.id);

			rows.push({
				kind: 'folder',
				folder,
				depth,
				hasChildren,
				isExpanded
			});

			if (isExpanded) {
				rows.push(...getExplorerRows(folder.id, depth + 1));

				for (const prompt of getFolderPrompts(folder.id)) {
					rows.push({
						kind: 'prompt',
						prompt,
						depth: depth + 1
					});
				}
			}
		}

		return rows;
	}

	function getFolderSubtreeIds(folderId: string): string[] {
		const descendants = [folderId];

		for (const folder of folders.filter((item) => item.parentId === folderId)) {
			descendants.push(...getFolderSubtreeIds(folder.id));
		}

		return descendants;
	}

	function isFolderInsideSubtree(folderId: string, ancestorId: string): boolean {
		let currentFolder = getFolderById(folderId);

		while (currentFolder?.parentId) {
			if (currentFolder.parentId === ancestorId) {
				return true;
			}

			currentFolder = getFolderById(currentFolder.parentId);
		}

		return false;
	}

	function closeTransientPanels(): void {
		nameModal = null;
		newPromptModal = null;
		deleteDialog = null;
		contextMenu = null;
	}

	function clearAutosaveTimer(): void {
		if (autosaveTimer) {
			window.clearTimeout(autosaveTimer);
			autosaveTimer = 0;
		}
	}

	function clearCopyFeedbackTimer(): void {
		if (copyFeedbackTimer) {
			window.clearTimeout(copyFeedbackTimer);
			copyFeedbackTimer = 0;
		}
	}

	function snapshotPrompt(prompt: PromptDocument): PromptDocument {
		return { ...prompt };
	}

	function queuePersist(nextFolders: PromptFolder[], nextPrompts: PromptDocument[]): Promise<void> {
		folders = nextFolders;
		prompts = nextPrompts;

		persistQueue = persistQueue
			.catch(() => undefined)
			.then(() =>
				savePromptManagerState({
					folders: nextFolders,
					prompts: nextPrompts
				})
			)
			.catch((error) => {
				console.error(error);
			});

		return persistQueue;
	}

	function isRecord(value: unknown): value is Record<string, unknown> {
		return typeof value === 'object' && value !== null;
	}

	function isFolderShape(value: unknown): value is PromptFolder {
		return (
			isRecord(value) &&
			typeof value.id === 'string' &&
			typeof value.name === 'string' &&
			(typeof value.parentId === 'string' || value.parentId === null) &&
			typeof value.createdAt === 'string'
		);
	}

	function isPromptShape(value: unknown): value is PromptDocument {
		return (
			isRecord(value) &&
			typeof value.id === 'string' &&
			typeof value.title === 'string' &&
			typeof value.content === 'string' &&
			typeof value.folderId === 'string' &&
			typeof value.createdAt === 'string' &&
			typeof value.updatedAt === 'string'
		);
	}

	function getRawImportedState(payload: unknown): unknown {
		if (
			isRecord(payload) &&
			payload.app === 'apps.marianialessandro.com/promptmanager' &&
			payload.version === 1 &&
			'data' in payload
		) {
			return payload.data;
		}

		return payload;
	}

	function validateImportedState(payload: unknown): PromptManagerState {
		const rawState = getRawImportedState(payload);

		if (!isRecord(rawState) || !Array.isArray(rawState.folders) || !Array.isArray(rawState.prompts)) {
			throw new Error('Il file non contiene un archivio valido del prompt manager.');
		}

		const nextFolders = rawState.folders.map((folder) => {
			if (!isFolderShape(folder)) {
				throw new Error('Il file contiene una cartella con struttura non valida.');
			}

			const name = normalizeLabel(folder.name);

			if (!name) {
				throw new Error('Il file contiene una cartella senza nome valido.');
			}

			return {
				...folder,
				name
			};
		});

		const nextPrompts = rawState.prompts.map((prompt) => {
			if (!isPromptShape(prompt)) {
				throw new Error('Il file contiene un prompt con struttura non valida.');
			}

			const title = normalizeLabel(prompt.title);

			if (!title) {
				throw new Error('Il file contiene un prompt senza titolo valido.');
			}

			return {
				...prompt,
				title
			};
		});

		const folderIds = new Set<string>();

		for (const folder of nextFolders) {
			if (folderIds.has(folder.id)) {
				throw new Error(`ID cartella duplicato rilevato: ${folder.id}.`);
			}

			folderIds.add(folder.id);
		}

		const promptIds = new Set<string>();

		for (const prompt of nextPrompts) {
			if (promptIds.has(prompt.id)) {
				throw new Error(`ID prompt duplicato rilevato: ${prompt.id}.`);
			}

			promptIds.add(prompt.id);
		}

		for (const folder of nextFolders) {
			if (folder.parentId === folder.id) {
				throw new Error(`La cartella "${folder.name}" non può avere se stessa come parent.`);
			}

			if (folder.parentId && !folderIds.has(folder.parentId)) {
				throw new Error(`La cartella "${folder.name}" punta a un parent inesistente.`);
			}
		}

		const folderMap = new Map(nextFolders.map((folder) => [folder.id, folder]));

		for (const folder of nextFolders) {
			const visited = new Set<string>([folder.id]);
			let currentParentId = folder.parentId;

			while (currentParentId) {
				if (visited.has(currentParentId)) {
					throw new Error(`La gerarchia delle cartelle contiene un ciclo che coinvolge "${folder.name}".`);
				}

				visited.add(currentParentId);
				currentParentId = folderMap.get(currentParentId)?.parentId ?? null;
			}
		}

		for (const prompt of nextPrompts) {
			if (!folderIds.has(prompt.folderId)) {
				throw new Error(`Il prompt "${prompt.title}" punta a una cartella inesistente.`);
			}
		}

		return {
			folders: nextFolders,
			prompts: nextPrompts
		};
	}

	function buildExportPayload(): PromptManagerExportPayload {
		return {
			app: 'apps.marianialessandro.com/promptmanager',
			version: 1,
			exportedAt: new Date().toISOString(),
			data: {
				folders: folders.map((folder) => ({ ...folder })),
				prompts: prompts.map((prompt) => ({ ...prompt }))
			}
		};
	}

	function formatExportFilename(): string {
		const now = new Date();
		const isoDate = [
			now.getFullYear(),
			String(now.getMonth() + 1).padStart(2, '0'),
			String(now.getDate()).padStart(2, '0')
		].join('-');

		return `prompt-manager-export-${isoDate}.json`;
	}

	function clearImportExportFeedback(): void {
		importExportMessage = null;
		importExportError = null;
	}

	function resetWorkspaceState(nextState: PromptManagerState): void {
		folders = nextState.folders;
		prompts = nextState.prompts;
		expandedFolderIds = getInitialExpandedFolderIds(nextState.folders, nextState.prompts);
		selectedFolderId = nextState.folders[0]?.id ?? null;
		selectedPromptId = null;
		editingPromptId = null;
		editingTitle = '';
		editingContent = '';
		editSessionSnapshot = null;
		contextMenu = null;
		infoDialog = null;
		deleteDialog = null;
		nameModal = null;
		newPromptModal = null;
	}

	function exportArchive(): void {
		clearImportExportFeedback();

		const payload = buildExportPayload();
		const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
		const downloadUrl = URL.createObjectURL(blob);
		const link = document.createElement('a');

		link.href = downloadUrl;
		link.download = formatExportFilename();
		document.body.append(link);
		link.click();
		link.remove();
		URL.revokeObjectURL(downloadUrl);

		importExportMessage = `Export completato: ${payload.data.folders.length} cartelle e ${payload.data.prompts.length} prompt.`;
	}

	function openImportPicker(): void {
		clearImportExportFeedback();
		importFileInput?.click();
	}

	async function importArchiveFromFile(event: Event): Promise<void> {
		const input = event.currentTarget as HTMLInputElement;
		const file = input.files?.[0];

		if (!file) {
			return;
		}

		clearImportExportFeedback();
		isImporting = true;

		try {
			const text = await file.text();
			const payload = JSON.parse(text) as unknown;
			const nextState = validateImportedState(payload);

			if (
				!window.confirm(
					`Importando "${file.name}" sostituirai l'archivio locale corrente con ${nextState.folders.length} cartelle e ${nextState.prompts.length} prompt. Procedere?`
				)
			) {
				return;
			}

			clearAutosaveTimer();
			await queuePersist(nextState.folders, nextState.prompts);
			resetWorkspaceState(nextState);
			importExportMessage = `Import completato da "${file.name}": ${nextState.folders.length} cartelle e ${nextState.prompts.length} prompt caricati.`;
		} catch (error) {
			importExportError =
				error instanceof Error ? error.message : 'Import fallito: file non leggibile.';
		} finally {
			isImporting = false;
			input.value = '';
		}
	}

	async function openNameModal(state: NameModalState): Promise<void> {
		closeTransientPanels();
		nameModal = state;
		await tick();
		nameInput?.focus();
		nameInput?.select();
	}

	async function openNewPromptCreationModal(): Promise<void> {
		if (!selectedFolderId) {
			return;
		}

		closeTransientPanels();
		newPromptModal = {
			folderId: selectedFolderId,
			title: '',
			content: ''
		};
		await tick();
		promptTitleInput?.focus();
	}

	async function openInfoDialog(promptId: string): Promise<void> {
		closeTransientPanels();
		infoDialog = {
			status: 'loading',
			promptId
		};
		await tick();
		infoDialog = {
			status: 'ready',
			promptId
		};
	}

	function selectFolder(folderId: string): void {
		selectedFolderId = folderId;
		selectedPromptId = null;
	}

	function selectPrompt(promptId: string): void {
		const prompt = getPromptById(promptId);

		if (!prompt) {
			return;
		}

		selectedPromptId = promptId;
		selectedFolderId = prompt.folderId;
		ensureExpanded(prompt.folderId);
	}

	function handleFolderRowClick(folderId: string): void {
		const folder = getFolderById(folderId);

		if (!folder) {
			return;
		}

		selectFolder(folderId);

		if (getFolderChildrenCount(folderId) > 0) {
			toggleExpanded(folderId);
		}
	}

	function handleFolderArrowClick(event: MouseEvent, folderId: string): void {
		event.stopPropagation();
		toggleExpanded(folderId);
	}

	function generateQuickPromptTitle(folderId: string): string {
		const titles = new Set(getFolderPrompts(folderId).map((prompt) => prompt.title));

		if (!titles.has('Nuovo prompt')) {
			return 'Nuovo prompt';
		}

		let index = 2;

		while (titles.has(`Nuovo prompt ${index}`)) {
			index += 1;
		}

		return `Nuovo prompt ${index}`;
	}

	async function createQuickPrompt(folderId: string): Promise<void> {
		const folder = getFolderById(folderId);

		if (!folder) {
			return;
		}

		const now = new Date().toISOString();
		const prompt: PromptDocument = {
			id: crypto.randomUUID(),
			title: generateQuickPromptTitle(folderId),
			content: '',
			folderId,
			createdAt: now,
			updatedAt: now
		};

		closeTransientPanels();
		await queuePersist(folders, [...prompts, prompt]);
		selectPrompt(prompt.id);
		await startEditing(prompt.id);
	}

	async function submitNameModal(): Promise<void> {
		const modal = nameModal;

		if (!modal) {
			return;
		}

		const value = normalizeLabel(modal.value);

		if (!value) {
			return;
		}

		if (modal.kind === 'create-root-folder' || modal.kind === 'create-child-folder') {
			const folder: PromptFolder = {
				id: crypto.randomUUID(),
				name: value,
				parentId: modal.kind === 'create-root-folder' ? null : modal.parentId,
				createdAt: new Date().toISOString()
			};

			await queuePersist([...folders, folder], prompts);
			ensureExpanded(folder.id);
			selectedFolderId = folder.id;
			selectedPromptId = null;
		}

		if (modal.kind === 'rename-folder') {
			const nextFolders = folders.map((folder) =>
				folder.id === modal.folderId ? { ...folder, name: value } : folder
			);

			await queuePersist(nextFolders, prompts);
		}

		if (modal.kind === 'rename-prompt') {
			const nextPrompts = prompts.map((prompt) =>
				prompt.id === modal.promptId
					? {
							...prompt,
							title: value,
							updatedAt: new Date().toISOString()
						}
					: prompt
			);

			if (editingPromptId === modal.promptId) {
				editingTitle = value;
			}

			await queuePersist(folders, nextPrompts);
		}

		nameModal = null;
	}

	async function submitNewPromptModal(): Promise<void> {
		if (!newPromptModal) {
			return;
		}

		const title = normalizeLabel(newPromptModal.title);

		if (!title) {
			return;
		}

		const now = new Date().toISOString();
		const prompt: PromptDocument = {
			id: crypto.randomUUID(),
			title,
			content: newPromptModal.content,
			folderId: newPromptModal.folderId,
			createdAt: now,
			updatedAt: now
		};

		await queuePersist(folders, [...prompts, prompt]);
		newPromptModal = null;
		selectPrompt(prompt.id);
	}

	function startNewRootFolder(): Promise<void> {
		return openNameModal({
			kind: 'create-root-folder',
			value: ''
		});
	}

	function startNewChildFolder(folderId: string): Promise<void> {
		return openNameModal({
			kind: 'create-child-folder',
			parentId: folderId,
			value: ''
		});
	}

	function startRenameFolder(folderId: string): Promise<void> {
		const folder = getFolderById(folderId);

		if (!folder) {
			return Promise.resolve();
		}

		return openNameModal({
			kind: 'rename-folder',
			folderId,
			value: folder.name
		});
	}

	function startRenamePrompt(promptId: string): Promise<void> {
		const prompt = getPromptById(promptId);

		if (!prompt) {
			return Promise.resolve();
		}

		return openNameModal({
			kind: 'rename-prompt',
			promptId,
			value: prompt.title
		});
	}

	function openDeleteFolderDialog(folderId: string): void {
		const folder = getFolderById(folderId);

		if (!folder) {
			return;
		}

		closeTransientPanels();
		deleteDialog = {
			kind: 'folder',
			folderId,
			name: folder.name
		};
	}

	function openDeletePromptDialog(promptId: string): void {
		const prompt = getPromptById(promptId);

		if (!prompt) {
			return;
		}

		closeTransientPanels();
		deleteDialog = {
			kind: 'prompt',
			promptId,
			name: prompt.title
		};
	}

	async function confirmDeletion(): Promise<void> {
		const dialog = deleteDialog;

		if (!dialog) {
			return;
		}

		if (dialog.kind === 'folder') {
			const subtree = new Set(getFolderSubtreeIds(dialog.folderId));
			const nextFolders = folders.filter((folder) => !subtree.has(folder.id));
			const removedPromptIds = new Set(
				prompts.filter((prompt) => subtree.has(prompt.folderId)).map((prompt) => prompt.id)
			);
			const nextPrompts = prompts.filter((prompt) => !removedPromptIds.has(prompt.id));

			if (selectedFolderId && subtree.has(selectedFolderId)) {
				selectedFolderId = null;
			}

			if (selectedPromptId && removedPromptIds.has(selectedPromptId)) {
				selectedPromptId = null;
			}

			if (editingPromptId && removedPromptIds.has(editingPromptId)) {
				editingPromptId = null;
				editingTitle = '';
				editingContent = '';
				editSessionSnapshot = null;
			}

			if (infoDialog && removedPromptIds.has(infoDialog.promptId)) {
				infoDialog = null;
			}

			expandedFolderIds = expandedFolderIds.filter((folderId) => !subtree.has(folderId));
			await queuePersist(nextFolders, nextPrompts);
		}

		if (dialog.kind === 'prompt') {
			const prompt = getPromptById(dialog.promptId);
			const nextPrompts = prompts.filter((item) => item.id !== dialog.promptId);

			if (selectedPromptId === dialog.promptId) {
				selectedPromptId = null;
			}

			if (editingPromptId === dialog.promptId) {
				editingPromptId = null;
				editingTitle = '';
				editingContent = '';
				editSessionSnapshot = null;
				clearAutosaveTimer();
			}

			if (infoDialog?.promptId === dialog.promptId) {
				infoDialog = null;
			}

			if (prompt) {
				selectedFolderId = prompt.folderId;
			}

			await queuePersist(folders, nextPrompts);
		}

		deleteDialog = null;
	}

	function openRootContextMenu(event: MouseEvent): void {
		event.preventDefault();
		contextMenu = {
			kind: 'root',
			x: event.clientX,
			y: event.clientY
		};
	}

	function openFolderContextMenu(event: MouseEvent, folderId: string): void {
		event.preventDefault();
		event.stopPropagation();
		contextMenu = {
			kind: 'folder',
			x: event.clientX,
			y: event.clientY,
			folderId
		};
	}

	function openPromptContextMenu(event: MouseEvent, promptId: string): void {
		event.preventDefault();
		event.stopPropagation();
		contextMenu = {
			kind: 'prompt',
			x: event.clientX,
			y: event.clientY,
			promptId
		};
	}

	async function startEditing(promptId: string): Promise<void> {
		const prompt = getPromptById(promptId);

		if (!prompt) {
			return;
		}

		clearAutosaveTimer();
		contextMenu = null;
		selectPrompt(promptId);
		editingPromptId = promptId;
		editingTitle = prompt.title;
		editingContent = prompt.content;
		editSessionSnapshot = snapshotPrompt(prompt);
		await tick();
		editorTextarea?.focus();
	}

	function scheduleAutosave(): void {
		if (!editingPromptId) {
			return;
		}

		clearAutosaveTimer();
		autosaveTimer = window.setTimeout(() => {
			void autosaveActivePrompt();
		}, AUTOSAVE_DELAY_MS);
	}

	async function autosaveActivePrompt(): Promise<void> {
		if (!editingPromptId) {
			return;
		}

		const title = normalizeLabel(editingTitle);

		if (!title) {
			return;
		}

		const prompt = getPromptById(editingPromptId);

		if (!prompt) {
			return;
		}

		const nextPrompts = prompts.map((item) =>
			item.id === editingPromptId
				? {
						...item,
						title,
						content: editingContent,
						updatedAt: new Date().toISOString()
					}
				: item
		);

		await queuePersist(folders, nextPrompts);
	}

	async function saveEditing(): Promise<void> {
		if (!editingPromptId) {
			return;
		}

		clearAutosaveTimer();

		const title = normalizeLabel(editingTitle);

		if (!title) {
			return;
		}

		const nextPrompts = prompts.map((prompt) =>
			prompt.id === editingPromptId
				? {
						...prompt,
						title,
						content: editingContent,
						updatedAt: new Date().toISOString()
					}
				: prompt
		);

		await queuePersist(folders, nextPrompts);
		editingPromptId = null;
		editSessionSnapshot = null;
	}

	async function cancelEditing(): Promise<void> {
		if (!editingPromptId || !editSessionSnapshot) {
			editingPromptId = null;
			return;
		}

		clearAutosaveTimer();
		await queuePersist(
			folders,
			prompts.map((prompt) => (prompt.id === editSessionSnapshot?.id ? editSessionSnapshot : prompt))
		);

		selectedPromptId = editSessionSnapshot.id;
		selectedFolderId = editSessionSnapshot.folderId;
		editingPromptId = null;
		editingTitle = '';
		editingContent = '';
		editSessionSnapshot = null;
	}

	function handleEditorTitleInput(event: Event): void {
		editingTitle = (event.currentTarget as HTMLInputElement).value;
		scheduleAutosave();
	}

	function handleEditorContentInput(event: Event): void {
		editingContent = (event.currentTarget as HTMLTextAreaElement).value;
		scheduleAutosave();
	}

	function handleEditorTabKey(event: KeyboardEvent): void {
		if (event.key !== 'Tab') {
			return;
		}

		event.preventDefault();

		const target = event.currentTarget as HTMLTextAreaElement;
		const start = target.selectionStart;
		const end = target.selectionEnd;
		const nextValue = `${editingContent.slice(0, start)}\t${editingContent.slice(end)}`;

		editingContent = nextValue;
		scheduleAutosave();

		queueMicrotask(() => {
			target.selectionStart = start + 1;
			target.selectionEnd = start + 1;
		});
	}

	async function copyPromptContent(promptId: string): Promise<void> {
		const prompt = getPromptById(promptId);

		if (!prompt) {
			return;
		}

		await navigator.clipboard.writeText(prompt.content);
		copiedPromptId = promptId;
		clearCopyFeedbackTimer();
		copyFeedbackTimer = window.setTimeout(() => {
			copiedPromptId = null;
			copyFeedbackTimer = 0;
		}, 1600);
	}

	function formatDate(value: string): string {
		return new Intl.DateTimeFormat('it-IT', {
			dateStyle: 'medium',
			timeStyle: 'short'
		}).format(new Date(value));
	}

	function getPromptFolderPath(folderId: string): string {
		const segments: string[] = [];
		let currentFolder = getFolderById(folderId);

		while (currentFolder) {
			segments.unshift(currentFolder.name);
			currentFolder = currentFolder.parentId ? getFolderById(currentFolder.parentId) : undefined;
		}

		return segments.join(' / ');
	}

	function getPromptLineCount(content: string): number {
		if (!content) {
			return 1;
		}

		return content.split(/\r?\n/).length;
	}

	function canDropFolderIntoTarget(folderId: string, targetFolderId: string): boolean {
		return folderId !== targetFolderId && !isFolderInsideSubtree(targetFolderId, folderId);
	}

	async function moveFolder(folderId: string, parentId: string | null): Promise<void> {
		const folder = getFolderById(folderId);

		if (!folder) {
			return;
		}

		if (parentId && !canDropFolderIntoTarget(folderId, parentId)) {
			window.alert('Operazione non valida: non puoi spostare una cartella dentro se stessa o una sua sottocartella.');
			return;
		}

		if (folder.parentId === parentId) {
			return;
		}

		const nextFolders = folders.map((item) =>
			item.id === folderId
				? {
						...item,
						parentId
					}
				: item
		);

		await queuePersist(nextFolders, prompts);
		selectedFolderId = folderId;
		selectedPromptId = null;
		ensureExpanded(folderId);
	}

	async function movePrompt(promptId: string, targetFolderId: string): Promise<void> {
		const prompt = getPromptById(promptId);

		if (!prompt || prompt.folderId === targetFolderId) {
			return;
		}

		const nextPrompts = prompts.map((item) =>
			item.id === promptId
				? {
						...item,
						folderId: targetFolderId,
						updatedAt: new Date().toISOString()
					}
				: item
		);

		await queuePersist(folders, nextPrompts);

		if (selectedPromptId === promptId || editingPromptId === promptId) {
			selectedFolderId = targetFolderId;
			ensureExpanded(targetFolderId);
		}
	}

	function handleDragStartFolder(event: DragEvent, folderId: string): void {
		dragging = {
			kind: 'folder',
			id: folderId
		};

		if (event.dataTransfer) {
			event.dataTransfer.setData('text/plain', folderId);
			event.dataTransfer.effectAllowed = 'move';
		}
	}

	function handleDragStartPrompt(event: DragEvent, promptId: string): void {
		dragging = {
			kind: 'prompt',
			id: promptId
		};

		if (event.dataTransfer) {
			event.dataTransfer.setData('text/plain', promptId);
			event.dataTransfer.effectAllowed = 'move';
		}
	}

	function handleDragEnd(): void {
		dragging = null;
		dropTargetFolderId = null;
		rootDropActive = false;
	}

	function handleFolderDragOver(event: DragEvent, folderId: string): void {
		if (!dragging) {
			return;
		}

		event.preventDefault();
		event.stopPropagation();
		dropTargetFolderId = folderId;
		rootDropActive = false;
	}

	async function handleFolderDrop(event: DragEvent, folderId: string): Promise<void> {
		if (!dragging) {
			return;
		}

		event.preventDefault();
		event.stopPropagation();

		if (dragging.kind === 'folder') {
			await moveFolder(dragging.id, folderId);
		}

		if (dragging.kind === 'prompt') {
			await movePrompt(dragging.id, folderId);
		}

		handleDragEnd();
	}

	function handleRootDragOver(event: DragEvent): void {
		if (!dragging || dragging.kind !== 'folder') {
			return;
		}

		event.preventDefault();
		rootDropActive = true;
		dropTargetFolderId = null;
	}

	async function handleRootDrop(event: DragEvent): Promise<void> {
		if (!dragging || dragging.kind !== 'folder') {
			return;
		}

		event.preventDefault();
		await moveFolder(dragging.id, null);
		handleDragEnd();
	}

	function handleRootDragLeave(event: DragEvent): void {
		if (event.currentTarget === event.target) {
			rootDropActive = false;
		}
	}

	function handleFolderRowKeydown(event: KeyboardEvent, folderId: string): void {
		if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			handleFolderRowClick(folderId);
		}
	}

	function handlePromptRowKeydown(event: KeyboardEvent, promptId: string): void {
		if (event.key === 'Enter' || event.key === ' ') {
			event.preventDefault();
			selectPrompt(promptId);
		}
	}

	function handleOverlayKeydown(event: KeyboardEvent, closer: () => void): void {
		if ((event.key === 'Enter' || event.key === ' ') && event.currentTarget === event.target) {
			event.preventDefault();
			closer();
		}
	}

	function handlePromptModalTextareaKeydown(event: KeyboardEvent): void {
		if (event.key === 'Enter' && !event.shiftKey) {
			event.preventDefault();
			void submitNewPromptModal();
		}
	}

	function getTopbarTitle(): string {
		const selectedPrompt = getPromptById(selectedPromptId);

		if (editingPromptId && selectedPrompt) {
			return selectedPrompt.title;
		}

		if (selectedPrompt) {
			return selectedPrompt.title;
		}

		const selectedFolder = getFolderById(selectedFolderId);

		if (selectedFolder) {
			return selectedFolder.name;
		}

		return 'Seleziona una cartella o un prompt';
	}

	function handleNameModalSubmit(event: SubmitEvent): void {
		event.preventDefault();
		void submitNameModal();
	}

	function handleNewPromptSubmit(event: SubmitEvent): void {
		event.preventDefault();
		void submitNewPromptModal();
	}

	function withFolderContext(handler: (folderId: string) => void | Promise<void>): void {
		if (contextMenu?.kind === 'folder') {
			void handler(contextMenu.folderId);
		}
	}

	function withPromptContext(handler: (promptId: string) => void | Promise<void>): void {
		if (contextMenu?.kind === 'prompt') {
			void handler(contextMenu.promptId);
		}
	}
</script>

<svelte:head>
	<title>Prompt manager | apps.marianialessandro.com</title>
	<meta
		name="description"
		content="Prompt manager locale con explorer gerarchico, editor testo e persistenza IndexedDB su apps.marianialessandro.com."
	/>
</svelte:head>

<section class="prompt-manager-page">
	<div class="workspace">
		<aside class="sidebar">
			<div class="sidebar-dragbar"></div>

			<div class="activity-bar">
				<button
					type="button"
					class="activity-button"
					title="Nuovo prompt"
					aria-label="Nuovo prompt"
					disabled={!selectedFolderId}
					onclick={openNewPromptCreationModal}
				>
					<svg class="action-icon" viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M7 4.75h6.25L18.25 9.75V19a1.25 1.25 0 0 1-1.25 1.25H7A1.25 1.25 0 0 1 5.75 19V6A1.25 1.25 0 0 1 7 4.75Z"
							fill="none"
							stroke="currentColor"
							stroke-linejoin="round"
							stroke-width="1.7"
						/>
						<path
							d="M13 4.75v4.5h4.5M12 10.75v6.5M8.75 14h6.5"
							fill="none"
							stroke="currentColor"
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="1.7"
						/>
					</svg>
				</button>

				<button
					type="button"
					class="activity-button"
					title="Nuova cartella"
					aria-label="Nuova cartella"
					onclick={startNewRootFolder}
				>
					<svg class="action-icon" viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M3.75 8.25A1.5 1.5 0 0 1 5.25 6.75h4.1l1.4 1.5h8A1.5 1.5 0 0 1 20.25 9.75v8.5a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-10Z"
							fill="none"
							stroke="currentColor"
							stroke-linejoin="round"
							stroke-width="1.7"
						/>
						<path
							d="M12 11.25v5.5M9.25 14h5.5"
							fill="none"
							stroke="currentColor"
							stroke-linecap="round"
							stroke-width="1.7"
						/>
					</svg>
				</button>

				<div class="activity-spacer"></div>

				<button
					type="button"
					class="activity-button"
					title="Impostazioni"
					aria-label="Impostazioni"
					onclick={() => {
						closeTransientPanels();
						settingsOpen = true;
					}}
				>
					<svg class="action-icon" viewBox="0 0 24 24" aria-hidden="true">
						<path
							d="M12 8.75a3.25 3.25 0 1 0 0 6.5a3.25 3.25 0 0 0 0-6.5Zm7.25 3.25l-1.78.64c-.08.27-.18.53-.31.78l.81 1.72l-1.9 1.9l-1.72-.81c-.25.13-.51.23-.78.31l-.64 1.78H10.12l-.64-1.78a6.9 6.9 0 0 1-.78-.31l-1.72.81l-1.9-1.9l.81-1.72a6.9 6.9 0 0 1-.31-.78L3.75 12l.64-1.88c.08-.27.18-.53.31-.78l-.81-1.72l1.9-1.9l1.72.81c.25-.13.51-.23.78-.31l.64-1.78h2.76l.64 1.78c.27.08.53.18.78.31l1.72-.81l1.9 1.9l-.81 1.72c.13.25.23.51.31.78L19.25 12Z"
							fill="none"
							stroke="currentColor"
							stroke-linejoin="round"
							stroke-width="1.55"
						/>
					</svg>
				</button>
			</div>

			<div
				class:root-drop-target={rootDropActive}
				class="explorer"
				role="presentation"
				oncontextmenu={openRootContextMenu}
				ondragover={handleRootDragOver}
				ondrop={handleRootDrop}
				ondragleave={handleRootDragLeave}
			>
				<div class="explorer-header">
					<div>
						<p class="panel-kicker">Explorer</p>
						<h2>Local tree</h2>
					</div>
					<p class="explorer-count">{folders.length} folders</p>
				</div>

				<div class="explorer-tree">
					{#if !isReady}
						<p class="explorer-empty">Caricamento archivio locale...</p>
					{:else if didLoadFail}
						<p class="explorer-empty">Impossibile leggere IndexedDB.</p>
					{:else if folders.length === 0}
						<div class="explorer-empty-state">
							<p class="explorer-empty">Nessuna cartella presente.</p>
							<button type="button" class="text-button" onclick={startNewRootFolder}>New Folder</button>
						</div>
					{:else}
						<ul class="tree-list" role="tree">
							{#each getExplorerRows() as row (`${row.kind}-${row.kind === 'folder' ? row.folder.id : row.prompt.id}`)}
								<li>
									{#if row.kind === 'folder'}
										<div
											aria-expanded={row.isExpanded}
											aria-selected={selectedFolderId === row.folder.id && !selectedPromptId}
											class:selected={selectedFolderId === row.folder.id && !selectedPromptId}
											class:dragging={dragging?.kind === 'folder' && dragging.id === row.folder.id}
											class:drop-target={dropTargetFolderId === row.folder.id}
											class="tree-row"
											draggable="true"
											role="treeitem"
											tabindex="0"
											onclick={() => handleFolderRowClick(row.folder.id)}
											onkeydown={(event) => handleFolderRowKeydown(event, row.folder.id)}
											oncontextmenu={(event) => openFolderContextMenu(event, row.folder.id)}
											ondragstart={(event) => handleDragStartFolder(event, row.folder.id)}
											ondragend={handleDragEnd}
											ondragover={(event) => handleFolderDragOver(event, row.folder.id)}
											ondrop={(event) => handleFolderDrop(event, row.folder.id)}
											style={`padding-left: ${0.75 + row.depth * 1.05}rem;`}
										>
											<button
												type="button"
												class="tree-arrow"
												class:is-expanded={row.isExpanded}
												disabled={!row.hasChildren}
												onclick={(event) => handleFolderArrowClick(event, row.folder.id)}
											>
												&gt;
											</button>

											<span class="tree-icon folder" aria-hidden="true">
												<svg viewBox="0 0 24 24">
													<path
														d="M3.75 8.25A1.5 1.5 0 0 1 5.25 6.75h4.1l1.4 1.5h8A1.5 1.5 0 0 1 20.25 9.75v8.5a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-10Z"
														fill="none"
														stroke="currentColor"
														stroke-linejoin="round"
														stroke-width="1.65"
													/>
												</svg>
											</span>
											<span class="tree-label">{row.folder.name}</span>
										</div>
									{:else}
										<div
											aria-selected={selectedPromptId === row.prompt.id}
											class:selected={selectedPromptId === row.prompt.id}
											class:dragging={dragging?.kind === 'prompt' && dragging.id === row.prompt.id}
											class="tree-row"
											draggable="true"
											role="treeitem"
											tabindex="0"
											onclick={() => selectPrompt(row.prompt.id)}
											onkeydown={(event) => handlePromptRowKeydown(event, row.prompt.id)}
											oncontextmenu={(event) => openPromptContextMenu(event, row.prompt.id)}
											ondragstart={(event) => handleDragStartPrompt(event, row.prompt.id)}
											ondragend={handleDragEnd}
											style={`padding-left: ${0.75 + row.depth * 1.05}rem;`}
										>
											<span class="tree-arrow spacer"></span>
											<span class="tree-icon prompt" aria-hidden="true">
												<svg viewBox="0 0 24 24">
													<path
														d="M7 4.75h6.25L18.25 9.75V19A1.25 1.25 0 0 1 17 20.25H7A1.25 1.25 0 0 1 5.75 19V6A1.25 1.25 0 0 1 7 4.75Z"
														fill="none"
														stroke="currentColor"
														stroke-linejoin="round"
														stroke-width="1.65"
													/>
													<path
														d="M13 4.75v4.5h4.5M8.5 13h7M8.5 16h5.25"
														fill="none"
														stroke="currentColor"
														stroke-linecap="round"
														stroke-width="1.65"
													/>
												</svg>
											</span>
											<span class="tree-label">{row.prompt.title}</span>
										</div>
									{/if}
								</li>
							{/each}
						</ul>
					{/if}
				</div>
			</div>
		</aside>

		<section class="content">
			<div class="content-topbar">
				<div class="topbar-copy">
					<p class="panel-kicker">Prompt manager</p>

					{#if editingPromptId}
						<input
							bind:this={topbarTitleInput}
							class="title-input"
							type="text"
							value={editingTitle}
							oninput={handleEditorTitleInput}
							placeholder="Titolo prompt"
						/>
					{:else}
						<h2>{getTopbarTitle()}</h2>
					{/if}

					{#if selectedPromptId && getPromptById(selectedPromptId)}
						<p class="topbar-meta">
							Creato il {formatDate(getPromptById(selectedPromptId)!.createdAt)}
						</p>
					{:else if selectedFolderId && getFolderById(selectedFolderId)}
						<p class="topbar-meta">Cartella attiva</p>
					{/if}
				</div>

				<div class="topbar-actions">
					{#if editingPromptId}
						<button type="button" class="text-button" onclick={cancelEditing}>Annulla</button>
						<button
							type="button"
							class="primary-button"
							disabled={!normalizeLabel(editingTitle)}
							onclick={saveEditing}
						>
							Salva
						</button>
					{:else if selectedPromptId}
						<button
							type="button"
							class="text-button danger-button"
							onclick={() => openDeletePromptDialog(selectedPromptId!)}
						>
							Delete
						</button>
						<button
							type="button"
							class="primary-button"
							onclick={() => startEditing(selectedPromptId!)}
						>
							Edit
						</button>
					{/if}
				</div>
			</div>

			<div class="content-panel">
				{#if !isReady}
					<div class="empty-state">
						<p class="empty-icon">[ ]</p>
						<h3>Caricamento...</h3>
					</div>
				{:else if editingPromptId}
					<div class="editor-shell">
						<textarea
							bind:this={editorTextarea}
							class="editor-textarea"
							value={editingContent}
							oninput={handleEditorContentInput}
							onkeydown={handleEditorTabKey}
							placeholder="Scrivi il contenuto del prompt."
						></textarea>
					</div>
				{:else if selectedPromptId && getPromptById(selectedPromptId)}
					{@const activePrompt = getPromptById(selectedPromptId)!}
					<div class="reader-shell">
						<div class="reader-toolbar">
							<button
								type="button"
								class="text-button"
								onclick={() => copyPromptContent(activePrompt.id)}
							>
								{copiedPromptId === activePrompt.id ? 'Copiato' : 'Copia'}
							</button>
						</div>

						<pre class="reader-code">{activePrompt.content}</pre>
					</div>
				{:else}
					<div class="empty-state">
						<p class="empty-icon">TXT</p>
						<h3>Nessun prompt aperto</h3>
						<p>
							{selectedFolderId
								? 'Seleziona o crea un prompt dalla sidebar.'
								: 'Seleziona una cartella o un prompt dalla sidebar.'}
						</p>
					</div>
				{/if}
			</div>
		</section>
	</div>
</section>

{#if contextMenu}
	<div
		class="context-menu"
		role="menu"
		style={`left: ${contextMenu.x}px; top: ${contextMenu.y}px;`}
	>
		{#if contextMenu.kind === 'root'}
			<button type="button" role="menuitem" onclick={startNewRootFolder}>New Folder</button>
		{:else if contextMenu.kind === 'folder'}
			<button type="button" role="menuitem" onclick={() => withFolderContext(createQuickPrompt)}>
				New Prompt
			</button>
			<button type="button" role="menuitem" onclick={() => withFolderContext(startNewChildFolder)}>
				New Folder
			</button>
			<button type="button" role="menuitem" onclick={() => withFolderContext(startRenameFolder)}>
				Rename
			</button>
			<button type="button" role="menuitem" class="danger-item" onclick={() => withFolderContext((folderId) => openDeleteFolderDialog(folderId))}>
				Delete
			</button>
		{:else}
			<button type="button" role="menuitem" onclick={() => withPromptContext(startRenamePrompt)}>
				Rename
			</button>
			<button type="button" role="menuitem" class="danger-item" onclick={() => withPromptContext((promptId) => openDeletePromptDialog(promptId))}>
				Delete
			</button>
			<div class="menu-divider"></div>
			<button type="button" role="menuitem" onclick={() => withPromptContext(openInfoDialog)}>
				Info
			</button>
		{/if}
	</div>
{/if}

{#if nameModal}
	<div
		class="overlay"
		role="button"
		tabindex="0"
		onclick={(event) => event.currentTarget === event.target && (nameModal = null)}
		onkeydown={(event) => handleOverlayKeydown(event, () => (nameModal = null))}
	>
		<div class="modal-card">
			<form onsubmit={handleNameModalSubmit}>
				<div class="modal-header">
					<p class="panel-kicker">Input</p>
					<h3>
						{nameModal.kind === 'rename-folder'
							? 'Rinomina cartella'
							: nameModal.kind === 'rename-prompt'
								? 'Rinomina prompt'
								: 'Nuova cartella'}
					</h3>
				</div>

				<label class="modal-field">
					<span>{nameModal.kind === 'rename-prompt' ? 'Titolo' : 'Nome'}</span>
					<input bind:this={nameInput} type="text" bind:value={nameModal.value} />
				</label>

				<div class="modal-actions">
					<button type="button" class="text-button" onclick={() => (nameModal = null)}>Annulla</button>
					<button
						type="submit"
						class="primary-button"
						disabled={!normalizeLabel(nameModal.value)}
					>
						{nameModal.kind === 'rename-folder' || nameModal.kind === 'rename-prompt'
							? 'Salva'
							: 'Crea cartella'}
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

{#if newPromptModal}
	<div
		class="overlay"
		role="button"
		tabindex="0"
		onclick={(event) => event.currentTarget === event.target && (newPromptModal = null)}
		onkeydown={(event) => handleOverlayKeydown(event, () => (newPromptModal = null))}
	>
		<div class="modal-card wide">
			<form onsubmit={handleNewPromptSubmit}>
				<div class="modal-header">
					<p class="panel-kicker">Prompt</p>
					<h3>Nuovo prompt</h3>
				</div>

				<div class="modal-grid">
					<label class="modal-field">
						<span>Titolo</span>
						<input bind:this={promptTitleInput} type="text" bind:value={newPromptModal.title} />
					</label>

					<label class="modal-field">
						<span>Contenuto</span>
						<textarea
							bind:this={promptContentInput}
							rows="9"
							bind:value={newPromptModal.content}
							onkeydown={handlePromptModalTextareaKeydown}
						></textarea>
					</label>
				</div>

				<div class="modal-actions">
					<button type="button" class="text-button" onclick={() => (newPromptModal = null)}>Annulla</button>
					<button type="submit" class="primary-button" disabled={!normalizeLabel(newPromptModal.title)}>
						Crea prompt
					</button>
				</div>
			</form>
		</div>
	</div>
{/if}

{#if deleteDialog}
	<div
		class="overlay"
		role="button"
		tabindex="0"
		onclick={(event) => event.currentTarget === event.target && (deleteDialog = null)}
		onkeydown={(event) => handleOverlayKeydown(event, () => (deleteDialog = null))}
	>
		<div class="modal-card compact">
			<div class="modal-header">
				<p class="panel-kicker">Delete</p>
				<h3>
					{deleteDialog.kind === 'folder' ? 'Elimina cartella' : 'Elimina prompt'}
				</h3>
			</div>

			<p class="confirm-copy">
				{deleteDialog.kind === 'folder'
					? `L'operazione elimina in modo ricorsivo "${deleteDialog.name}" e tutto il suo contenuto.`
					: `L'operazione elimina definitivamente "${deleteDialog.name}".`}
			</p>

			<div class="modal-actions">
				<button type="button" class="text-button" onclick={() => (deleteDialog = null)}>Annulla</button>
				<button type="button" class="danger-button solid" onclick={confirmDeletion}>Elimina</button>
			</div>
		</div>
	</div>
{/if}

{#if infoDialog}
	<div
		class="overlay info-overlay"
		role="button"
		tabindex="0"
		onclick={(event) => event.currentTarget === event.target && (infoDialog = null)}
		onkeydown={(event) => handleOverlayKeydown(event, () => (infoDialog = null))}
	>
		<div class="info-card">
			{#if infoDialog.status === 'loading'}
				<p>Caricamento informazioni...</p>
			{:else if getPromptById(infoDialog.promptId)}
				{@const prompt = getPromptById(infoDialog.promptId)!}
				<div class="info-header">
					<div>
						<p class="panel-kicker">Informazioni</p>
						<h3>{prompt.title}</h3>
						<p class="info-subtitle">Prompt</p>
					</div>
					<button type="button" class="close-button" onclick={() => (infoDialog = null)}>x</button>
				</div>

				<div class="info-sections">
					<section>
						<h4>Generali</h4>
						<dl>
							<div><dt>Nome</dt><dd>{prompt.title}</dd></div>
							<div><dt>Tipo</dt><dd>Prompt</dd></div>
							<div><dt>Cartella</dt><dd>{getPromptFolderPath(prompt.folderId)}</dd></div>
							<div><dt>ID</dt><dd>{prompt.id}</dd></div>
						</dl>
					</section>

					<section>
						<h4>Date</h4>
						<dl>
							<div><dt>Creato</dt><dd>{formatDate(prompt.createdAt)}</dd></div>
							<div><dt>Ultima modifica</dt><dd>{formatDate(prompt.updatedAt)}</dd></div>
						</dl>
					</section>

					<section>
						<h4>Contenuto</h4>
						<dl>
							<div><dt>Caratteri</dt><dd>{prompt.content.length}</dd></div>
							<div><dt>Righe</dt><dd>{getPromptLineCount(prompt.content)}</dd></div>
						</dl>
					</section>
				</div>
			{/if}
		</div>
	</div>
{/if}

{#if settingsOpen}
	<div
		class="overlay settings-overlay"
		role="button"
		tabindex="0"
		onclick={(event) => event.currentTarget === event.target && (settingsOpen = false)}
		onkeydown={(event) => handleOverlayKeydown(event, () => (settingsOpen = false))}
	>
		<aside class="settings-panel">
			<div class="info-header">
				<div>
					<p class="panel-kicker">Impostazioni</p>
					<h3>Settings</h3>
				</div>
				<button type="button" class="close-button" onclick={() => (settingsOpen = false)}>x</button>
			</div>

			<div class="settings-grid">
				<section class="settings-card">
					<h4>UI</h4>
					<p>
						Area preparatoria per preferenze future su layout, comportamento editor e scorciatoie.
					</p>
				</section>

				<section class="settings-card">
					<h4>Explorer</h4>
					<p>
						La sidebar ordina cartelle e prompt in ordine alfabetico, con drag and drop per
						riorganizzare la struttura locale.
					</p>
				</section>

				<section class="settings-card">
					<h4>Persistenza</h4>
					<p>
						Tutti i dati restano nel browser tramite IndexedDB e vengono ricaricati in
						automatico alla sessione successiva.
					</p>
				</section>

				<section class="settings-card">
					<h4>Backup dati</h4>
					<p>
						Esporta l'intero archivio locale in JSON oppure reimporta un backup per
						sostituire il contenuto corrente del prompt manager.
					</p>

					<div class="settings-actions">
						<button type="button" class="primary-button" onclick={exportArchive}>
							Esporta JSON
						</button>
						<button
							type="button"
							class="text-button"
							onclick={openImportPicker}
							disabled={isImporting}
						>
							{isImporting ? 'Import in corso...' : 'Importa JSON'}
						</button>
						<input
							bind:this={importFileInput}
							class="visually-hidden-input"
							type="file"
							accept="application/json,.json"
							onchange={importArchiveFromFile}
						/>
					</div>

					<p class="settings-meta">
						Archivio corrente: {folders.length} cartelle, {prompts.length} prompt.
					</p>

					{#if importExportMessage}
						<p class="settings-feedback success">{importExportMessage}</p>
					{/if}

					{#if importExportError}
						<p class="settings-feedback error">{importExportError}</p>
					{/if}
				</section>
			</div>
		</aside>
	</div>
{/if}

<style>
	.prompt-manager-page {
		display: flex;
		flex: 1;
		min-height: 0;
		height: 100%;
		width: 100%;
		background: linear-gradient(180deg, rgba(247, 247, 246, 0.92) 0%, rgba(255, 255, 255, 0.98) 100%);
	}

	.sidebar,
	.explorer,
	.content-topbar,
	.content-panel,
	.modal-card,
	.info-card,
	.settings-panel {
		border: 1px solid var(--line);
		border-radius: 2rem;
		background:
			linear-gradient(180deg, rgba(255, 255, 255, 0.96) 0%, rgba(252, 252, 251, 0.99) 100%);
		box-shadow: var(--shadow);
	}

	.explorer,
	.content-topbar,
	.content-panel,
	.modal-card,
	.info-card,
	.settings-panel {
		position: relative;
		overflow: hidden;
	}

	.explorer::before,
	.content-topbar::before,
	.content-panel::before,
	.modal-card::before,
	.info-card::before,
	.settings-panel::before {
		content: '';
		position: absolute;
		inset: 0;
		background:
			linear-gradient(90deg, rgba(0, 0, 0, 0.03) 1px, transparent 1px),
			linear-gradient(rgba(0, 0, 0, 0.03) 1px, transparent 1px);
		background-size: 24px 24px;
		mask-image: linear-gradient(to bottom, rgba(0, 0, 0, 0.18), rgba(0, 0, 0, 0));
		pointer-events: none;
	}

	.modal-card,
	.info-card,
	.settings-panel {
		padding: clamp(1.25rem, 2vw, 1.75rem);
	}

	.panel-kicker,
	.topbar-meta,
	.explorer-count,
	.info-subtitle {
		color: var(--muted);
	}

	.panel-kicker {
		margin: 0 0 0.75rem;
		font-size: 0.82rem;
		font-weight: 700;
		letter-spacing: 0.16em;
		text-transform: uppercase;
	}

	h2,
	h3,
	h4,
	p {
		position: relative;
		z-index: 1;
		margin: 0;
	}

	h2,
	h3 {
		line-height: 0.96;
		letter-spacing: -0.05em;
		word-break: break-word;
	}

	h2 {
		font-size: clamp(1.45rem, 2vw, 2rem);
	}

	h3 {
		font-size: clamp(1.35rem, 2vw, 1.75rem);
	}

	h4 {
		font-size: 0.95rem;
		letter-spacing: 0.01em;
	}

	.workspace {
		flex: 1;
		display: grid;
		grid-template-columns: minmax(18rem, 23rem) minmax(0, 1fr);
		gap: 1rem;
		align-items: stretch;
		padding: 1rem;
		min-height: 100%;
		height: 100%;
		box-sizing: border-box;
	}

	.sidebar {
		display: grid;
		grid-template-columns: 4.2rem minmax(0, 1fr);
		gap: 1rem;
		padding: 0;
		height: 100%;
		min-height: 0;
		align-items: stretch;
		background: transparent;
		border: none;
		box-shadow: none;
		position: relative;
	}

	.sidebar-dragbar,
	.content-topbar {
		-webkit-app-region: drag;
	}

	.sidebar-dragbar {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 1.2rem;
		border-radius: 999px;
		opacity: 0.001;
	}

	.activity-bar,
	.explorer,
	.content {
		min-height: 0;
	}

	.activity-bar {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.65rem;
		padding: 0.6rem 0.45rem;
		height: 100%;
		border: 1px solid var(--line);
		border-radius: 1.6rem;
		background: rgba(255, 255, 255, 0.75);
	}

	.activity-spacer {
		flex: 1;
	}

	.activity-button,
	.text-button,
	.primary-button,
	.close-button {
		-webkit-app-region: no-drag;
	}

	.activity-button,
	.text-button,
	.primary-button,
	.close-button,
	.danger-button {
		border: 1px solid var(--line);
		background: transparent;
		color: var(--fg);
		border-radius: 999px;
		font: inherit;
		cursor: pointer;
		transition:
			transform 120ms ease,
			background-color 120ms ease,
			border-color 120ms ease;
	}

	.activity-button {
		display: grid;
		place-items: center;
		width: 2.8rem;
		height: 2.8rem;
		padding: 0;
	}

	.action-icon {
		width: 1.1rem;
		height: 1.1rem;
	}

	.activity-button:hover:enabled,
	.text-button:hover,
	.primary-button:hover,
	.close-button:hover,
	.danger-button:hover {
		transform: translateY(-1px);
	}

	.activity-button:disabled {
		opacity: 0.45;
		cursor: not-allowed;
	}

	.explorer {
		display: grid;
		grid-template-rows: auto minmax(0, 1fr);
		height: 100%;
		padding: 1rem;
	}

	.root-drop-target {
		border-color: rgba(255, 62, 0, 0.45);
		box-shadow:
			var(--shadow),
			0 0 0 3px rgba(255, 62, 0, 0.08);
	}

	.explorer-header,
	.reader-toolbar,
	.info-header {
		position: relative;
		z-index: 1;
		display: flex;
		align-items: start;
		justify-content: space-between;
		gap: 1rem;
	}

	.explorer-tree {
		position: relative;
		z-index: 1;
		margin-top: 1rem;
		min-height: 0;
		overflow: auto;
	}

	.explorer-empty-state,
	.empty-state {
		display: grid;
		place-items: center;
		align-content: center;
		gap: 0.65rem;
		min-height: 100%;
		text-align: center;
		padding: 2rem 1rem;
	}

	.explorer-empty,
	.empty-state p,
	.confirm-copy,
	.settings-card p {
		color: var(--muted);
		line-height: 1.6;
	}

	.tree-list {
		list-style: none;
		padding: 0;
		margin: 0;
		display: grid;
		gap: 0.2rem;
	}

	.tree-row {
		display: grid;
		grid-template-columns: 1.5rem 2.4rem minmax(0, 1fr);
		align-items: center;
		min-height: 2.3rem;
		padding: 0.25rem 0.5rem;
		border-radius: 0.95rem;
		cursor: pointer;
		gap: 0.3rem;
	}

	.tree-row:hover {
		background: rgba(11, 15, 20, 0.05);
	}

	.tree-row.selected {
		background: rgba(255, 62, 0, 0.11);
		border: 1px solid rgba(255, 62, 0, 0.16);
	}

	.tree-row.dragging {
		opacity: 0.48;
	}

	.tree-row.drop-target {
		background: rgba(255, 62, 0, 0.08);
		border: 1px solid rgba(255, 62, 0, 0.22);
	}

	.tree-arrow {
		display: inline-grid;
		place-items: center;
		width: 1.4rem;
		height: 1.4rem;
		padding: 0;
		border: none;
		background: transparent;
		color: var(--muted);
		font: inherit;
		cursor: pointer;
		transform: rotate(0deg);
		transition: transform 120ms ease;
	}

	.tree-arrow.is-expanded {
		transform: rotate(90deg);
	}

	.tree-arrow:disabled {
		opacity: 0.22;
		cursor: default;
	}

	.tree-arrow.spacer {
		cursor: default;
	}

	.tree-icon {
		display: inline-grid;
		place-items: center;
		width: 2rem;
		height: 1.5rem;
		border-radius: 999px;
		border: 1px solid rgba(11, 15, 20, 0.08);
		background: rgba(255, 255, 255, 0.88);
	}

	.tree-icon svg {
		width: 1rem;
		height: 1rem;
	}

	.tree-icon.folder {
		color: #915900;
		background: rgba(255, 243, 224, 0.9);
	}

	.tree-icon.prompt {
		color: #1d4e89;
		background: rgba(232, 242, 255, 0.95);
	}

	.tree-label {
		min-width: 0;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.content {
		display: grid;
		grid-template-rows: auto minmax(0, 1fr);
		gap: 0.85rem;
		min-height: 0;
	}

	.content-topbar {
		display: flex;
		align-items: start;
		justify-content: space-between;
		gap: 1rem;
		padding: 1rem 1.25rem;
	}

	.topbar-copy {
		display: grid;
		gap: 0.45rem;
		min-width: 0;
	}

	.topbar-actions {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.65rem;
		position: relative;
		z-index: 1;
	}

	.title-input {
		width: min(42rem, 100%);
		padding: 0;
		border: none;
		background: transparent;
		font: inherit;
		font-size: clamp(1.45rem, 2vw, 2rem);
		font-weight: 400;
		letter-spacing: -0.05em;
		outline: none;
		-webkit-app-region: no-drag;
	}

	.topbar-meta,
	.explorer-count,
	.info-subtitle {
		font-size: 0.95rem;
	}

	.content-panel {
		padding: 1rem;
		min-height: 0;
	}

	.reader-shell,
	.editor-shell {
		position: relative;
		z-index: 1;
		display: grid;
		min-height: 100%;
	}

	.reader-shell {
		grid-template-rows: auto minmax(0, 1fr);
		gap: 0.75rem;
	}

	.reader-toolbar {
		justify-content: end;
		padding: 0;
	}

	.reader-code,
	.editor-textarea {
		width: 100%;
		min-height: 100%;
		border: 1px solid rgba(11, 15, 20, 0.08);
		border-radius: 1.35rem;
		padding: 1.15rem 1.2rem;
		background: rgba(255, 255, 255, 0.82);
		font-family: var(--font-mono);
		font-size: 0.97rem;
		line-height: 1.65;
		color: var(--fg);
	}

	.reader-code {
		margin: 0;
		white-space: pre-wrap;
		word-break: break-word;
		overflow: auto;
	}

	.editor-textarea {
		resize: none;
		outline: none;
	}

	.empty-state {
		min-height: 100%;
	}

	.empty-icon {
		display: inline-grid;
		place-items: center;
		min-width: 4rem;
		min-height: 4rem;
		padding: 0.75rem 1rem;
		border-radius: 1.25rem;
		border: 1px solid var(--line);
		background: rgba(255, 255, 255, 0.88);
		font-size: 0.88rem;
		font-weight: 700;
		letter-spacing: 0.16em;
	}

	.text-button,
	.primary-button,
	.danger-button {
		padding: 0.78rem 1.05rem;
		font-weight: 600;
	}

	.primary-button {
		background: var(--fg);
		color: var(--bg);
		border-color: var(--fg);
	}

	.danger-button,
	.danger-item {
		color: #b42318;
	}

	.danger-button.solid {
		background: #b42318;
		color: white;
		border-color: #b42318;
	}

	.overlay {
		position: fixed;
		inset: 0;
		z-index: 40;
		display: grid;
		place-items: center;
		padding: 1.25rem;
		background: rgba(11, 15, 20, 0.34);
		backdrop-filter: blur(8px);
	}

	.modal-card {
		width: min(32rem, 100%);
	}

	.modal-card.wide {
		width: min(42rem, 100%);
	}

	.modal-card.compact {
		width: min(28rem, 100%);
	}

	.modal-header,
	.modal-grid,
	.modal-actions,
	.info-sections,
	.settings-grid {
		position: relative;
		z-index: 1;
	}

	.modal-grid,
	.info-sections,
	.settings-grid {
		display: grid;
		gap: 1rem;
		margin-top: 1.2rem;
	}

	.modal-field {
		display: grid;
		gap: 0.6rem;
		margin-top: 1.1rem;
	}

	.modal-field span {
		font-weight: 600;
	}

	.modal-field input,
	.modal-field textarea {
		width: 100%;
		border: 1px solid var(--line);
		border-radius: 1rem;
		padding: 0.95rem 1rem;
		background: rgba(255, 255, 255, 0.92);
		font: inherit;
	}

	.modal-field textarea {
		resize: vertical;
	}

	.modal-actions {
		display: flex;
		justify-content: end;
		gap: 0.75rem;
		margin-top: 1.25rem;
	}

	.context-menu {
		position: fixed;
		z-index: 50;
		display: grid;
		gap: 0.2rem;
		min-width: 12rem;
		padding: 0.45rem;
		border: 1px solid var(--line);
		border-radius: 1rem;
		background: rgba(255, 255, 255, 0.96);
		box-shadow: 0 16px 32px rgba(11, 15, 20, 0.12);
		backdrop-filter: blur(10px);
	}

	.context-menu button {
		text-align: left;
		padding: 0.75rem 0.8rem;
		border: none;
		border-radius: 0.75rem;
		background: transparent;
		font: inherit;
		cursor: pointer;
	}

	.context-menu button:hover {
		background: rgba(11, 15, 20, 0.05);
	}

	.menu-divider {
		height: 1px;
		margin: 0.2rem 0.1rem;
		background: var(--line);
	}

	.info-overlay {
		align-items: center;
	}

	.info-card {
		width: min(40rem, 100%);
		max-height: min(44rem, calc(100vh - 2.5rem));
		overflow: auto;
	}

	.info-sections section,
	.settings-card {
		padding: 1rem;
		border: 1px solid rgba(11, 15, 20, 0.08);
		border-radius: 1.2rem;
		background: rgba(255, 255, 255, 0.72);
	}

	.settings-actions {
		position: relative;
		z-index: 1;
		display: flex;
		flex-wrap: wrap;
		gap: 0.75rem;
		margin-top: 1rem;
	}

	.settings-meta,
	.settings-feedback {
		position: relative;
		z-index: 1;
		margin-top: 0.9rem;
		font-size: 0.95rem;
	}

	.settings-feedback.success {
		color: #1f7a3d;
	}

	.settings-feedback.error {
		color: #b42318;
	}

	.visually-hidden-input {
		position: absolute;
		width: 1px;
		height: 1px;
		padding: 0;
		margin: -1px;
		overflow: hidden;
		clip: rect(0 0 0 0);
		white-space: nowrap;
		border: 0;
	}

	.info-sections dl {
		display: grid;
		gap: 0.8rem;
		margin: 0.8rem 0 0;
	}

	.info-sections dl div {
		display: grid;
		grid-template-columns: minmax(7rem, 10rem) minmax(0, 1fr);
		gap: 0.85rem;
	}

	.info-sections dt {
		color: var(--muted);
	}

	.info-sections dd {
		margin: 0;
		word-break: break-word;
	}

	.close-button {
		width: 2.4rem;
		height: 2.4rem;
		padding: 0;
	}

	.settings-overlay {
		justify-items: end;
	}

	.settings-panel {
		width: min(28rem, 100%);
		height: calc(100vh - 2.5rem);
	}

	.settings-grid {
		margin-top: 1.35rem;
	}

	@media (max-width: 1080px) {
		.workspace {
			grid-template-columns: minmax(16rem, 19rem) minmax(0, 1fr);
		}
	}

	@media (max-width: 900px) {
		.workspace {
			grid-template-columns: 1fr;
			min-height: auto;
		}

		.sidebar {
			display: none;
		}
	}

	@media (max-width: 720px) {
		.content-topbar {
			flex-direction: column;
		}

		.topbar-actions {
			width: 100%;
		}

		.info-card,
		.settings-panel {
			width: 100%;
			max-height: calc(100vh - 2rem);
			height: auto;
		}
	}

	@media (max-width: 640px) {
		.workspace,
		.modal-card,
		.info-card,
		.settings-panel,
		.content-topbar,
		.content-panel {
			border-radius: 1.45rem;
		}

		.overlay {
			padding: 0.85rem;
		}

		.info-sections dl div {
			grid-template-columns: 1fr;
		}
	}
</style>
