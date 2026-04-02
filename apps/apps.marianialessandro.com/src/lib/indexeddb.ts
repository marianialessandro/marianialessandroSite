export type PlaygroundCheckpoint = {
	id: string;
	label: string;
	createdAt: string;
};

export type PlaygroundState = {
	draft: string;
	updatedAt: string | null;
	checkpoints: PlaygroundCheckpoint[];
};

const DB_NAME = 'apps-marianialessandro';
const STORE_NAME = 'kv';
const STATE_KEY = 'playground-state';
const DB_VERSION = 1;

const DEFAULT_STATE: PlaygroundState = {
	draft: '',
	updatedAt: null,
	checkpoints: []
};

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

export async function loadPlaygroundState(): Promise<PlaygroundState> {
	return withStore('readonly', (store) => {
		return new Promise((resolve, reject) => {
			const request = store.get(STATE_KEY);

			request.onsuccess = () => {
				const result = request.result as StoredRecord<PlaygroundState> | undefined;
				resolve(result?.value ?? DEFAULT_STATE);
			};
			request.onerror = () =>
				reject(request.error ?? new Error('Impossibile leggere lo stato salvato.'));
		});
	});
}

export async function savePlaygroundState(state: PlaygroundState): Promise<void> {
	await withStore('readwrite', (store) => {
		return new Promise<void>((resolve, reject) => {
			const request = store.put({
				key: STATE_KEY,
				value: state
			} satisfies StoredRecord<PlaygroundState>);

			request.onsuccess = () => resolve();
			request.onerror = () =>
				reject(request.error ?? new Error('Impossibile salvare lo stato in IndexedDB.'));
		});
	});
}

export async function resetPlaygroundState(): Promise<PlaygroundState> {
	await savePlaygroundState(DEFAULT_STATE);
	return DEFAULT_STATE;
}
