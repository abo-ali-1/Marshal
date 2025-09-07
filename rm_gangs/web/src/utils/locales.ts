import { printf } from 'fast-printf';
import locale from '../../../locales/en.json';
import { IsEnvBrowser } from '@utils/eventsHandlers';

const locales: Record<string, string | number> = {};

declare global {
	interface String {
		format(...args: any[]): string;
	}
}

String.prototype.format = function (...args: any[]): string {
	return printf(this as string, ...args);
};

export function setLocale(data: typeof locale.ui) {
	if (IsEnvBrowser()) {
		for (const [key, value] of Object.entries(locale.ui)) {
			locales[key] = value;
		}
		return;
	}
	for (const key in locales) locales[key] = key;
	for (const [key, value] of Object.entries(data)) {
		locales[key] = value;
	}
}

export default locales as typeof locale.ui;
