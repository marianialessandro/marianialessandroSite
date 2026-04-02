export type PromptFolder = {
	id: string;
	name: string;
	parentId: string | null;
	createdAt: string;
};

export type PromptDocument = {
	id: string;
	title: string;
	content: string;
	folderId: string;
	createdAt: string;
	updatedAt: string;
};

export type PromptManagerState = {
	folders: PromptFolder[];
	prompts: PromptDocument[];
};

export const DEFAULT_PROMPT_MANAGER_STATE: PromptManagerState = {
	folders: [],
	prompts: []
};
