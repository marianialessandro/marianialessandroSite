import {
	DEFAULT_PROMPT_MANAGER_STATE,
	type PromptManagerState
} from '$lib/promptmanager/types';

const DB_NAME = 'apps-marianialessandro';
const STORE_NAME = 'kv';
const DB_VERSION = 2;
const PROMPT_MANAGER_KEY = 'prompt-manager-state';

type StoredRecord<T> = {
	key: string;
	value: T;
};

function openDatabase(): Promise<IDBDatabase> {
	return new Promise((resolve, reject) => {
		const request = indexedDB.open(DB_NAME, DB_VERSION);

		request.onupgradeneeded = () => {
			const database = request.result;

			if (!database.objectStoreNames.contains(STORE_NAME)) {
				database.createObjectStore(STORE_NAME, { keyPath: 'key' });
			}
		};

		request.onsuccess = () => resolve(request.result);
		request.onerror = () => reject(request.error ?? new Error('Impossibile aprire IndexedDB.'));
	});
}

async function withStore<T>(
	mode: IDBTransactionMode,
	handler: (store: IDBObjectStore) => Promise<T>
): Promise<T> {
	const database = await openDatabase();

	try {
		const transaction = database.transaction(STORE_NAME, mode);
		const store = transaction.objectStore(STORE_NAME);
		return await handler(store);
	} finally {
		database.close();
	}
}

function cloneState(state: PromptManagerState): PromptManagerState {
	return {
		folders: state.folders.map((folder) => ({ ...folder })),
		prompts: state.prompts.map((prompt) => ({ ...prompt }))
	};
}

export async function loadPromptManagerState(): Promise<PromptManagerState> {
	return withStore('readonly', (store) => {
		return new Promise((resolve, reject) => {
			const request = store.get(PROMPT_MANAGER_KEY);

			request.onsuccess = () => {
				const result = request.result as StoredRecord<PromptManagerState> | undefined;
				resolve(cloneState(result?.value ?? DEFAULT_PROMPT_MANAGER_STATE));
			};
			request.onerror = () =>
				reject(request.error ?? new Error('Impossibile leggere lo stato del prompt manager.'));
		});
	});
}

export async function savePromptManagerState(state: PromptManagerState): Promise<void> {
	await withStore('readwrite', (store) => {
		return new Promise<void>((resolve, reject) => {
			const request = store.put({
				key: PROMPT_MANAGER_KEY,
				value: cloneState(state)
			} satisfies StoredRecord<PromptManagerState>);

			request.onsuccess = () => resolve();
			request.onerror = () =>
				reject(request.error ?? new Error('Impossibile salvare il prompt manager.'));
		});
	});
}
