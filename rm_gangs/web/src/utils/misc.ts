import { GANGS, NOTIFICATIONS, PLAYER, WARS } from '@stores/stores';
import { get } from 'svelte/store';

export const notify = (text: string, position: string = 'topLeft', icon: string = 'circle-info', timer: number = 5000) => {
	const newId = Math.floor(Math.random() * 99999);
	const newNotification = { id: newId, text, position, icon, timer };

	NOTIFICATIONS.update((notifications) => [...notifications, newNotification]);

	setTimeout(() => {
		NOTIFICATIONS.update((notifications) => notifications.filter(({ id }) => id !== newId));
	}, timer);
};

export const canDeclareWar = (targetName: string) => {
	const player = get(PLAYER);
	if (!player.gang.isboss) return false;
	if (player.gang.name == targetName) return false;

	const wars = get(WARS);
	if (wars.length === 0) return true;

	const war = wars.find(({ initiator, target, accepted, cancelled, finishDate }) => {
		if ((initiator === targetName && target === player.gang.name) || (initiator === player.gang.name && target === targetName)) {
			if (accepted) return !finishDate;
			else return !cancelled;
		} else return false;
	});

	if (war) return false;
	return true;
};

export const getGangData = (gangName: string) => get(GANGS).find(({ name }) => name == gangName) ?? { label: 'Unknown?', name: '_unknown', color: '#FFFFFF' };
export const getGangLabelText = (label: string = 'Unknown', color: string = '#FFFFFF') => `<b style="color: ${color}">${label}</b>`;

export const calculateWarWinRate = (gangName: string) => {
	let warCount = 0;
	let winCount = 0;

	const wars = get(WARS);
	wars.forEach(({ initiator, target, accepted, cancelled, surrendered, finishDate, initiatorScore, targetScore }) => {
		if (accepted && !cancelled && (initiator == gangName || target == gangName)) {
			warCount++;

			if (finishDate) {
				if (surrendered) {
					if ((surrendered == 1 && target == gangName) || (surrendered == 2 && initiator == gangName)) winCount++;
				} else if ((initiator == gangName && initiatorScore > targetScore) || (target == gangName && targetScore > initiatorScore)) winCount++;
			}
		}
	});

	if (warCount == 0) return 0;
	else return parseFloat(((winCount / warCount) * 100).toFixed(2));
};

export function getRemainingTime(timestamp: number, currentTimestamp?: number) {
	currentTimestamp = currentTimestamp ?? new Date().getTime();
	const remainingTime = timestamp - currentTimestamp;

	const hour = Math.floor(remainingTime / (1000 * 60 * 60));
	const minute = Math.floor((remainingTime % (1000 * 60 * 60)) / (1000 * 60));
	const second = Math.floor((remainingTime % (1000 * 60)) / 1000);

	return { hour, minute, second };
}

export const isImageUrlValid = (url: string): Promise<boolean> => {
	return new Promise((resolve) => {
		const img = new Image();
		img.onload = () => resolve(true);
		img.onerror = () => resolve(false);
		img.src = url;
	});
};

export const calculateTurfDominance = (initiatorCount = 0, targetCount = 0) => {
	const initiator = Math.round((initiatorCount / (initiatorCount + targetCount)) * 100) || 0;
	const target = Math.round((targetCount / (targetCount + initiatorCount)) * 100) || 0;
	return { initiator, target, winner: initiator > target ? initiator : target };
};
