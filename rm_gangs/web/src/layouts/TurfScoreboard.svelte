<script lang="ts">
	import { TURF_EVENT_ID, TURF_WARS, CONFIG } from '@stores/stores';
	import type { TurfWar } from '@typings/misc';
	import locales from '@utils/locales';
	import { getGangData, getGangLabelText, getRemainingTime, calculateTurfDominance } from '@utils/misc';
	import { onDestroy, onMount } from 'svelte';
	import { fade } from 'svelte/transition';

	let turfWar: TurfWar;
	let initiator: any;
	let target: any;
	let remainingTime: any;

	$: {
		turfWar = $TURF_WARS.find(({ id }) => id == $TURF_EVENT_ID);
		if (turfWar) {
			initiator = getGangData(turfWar.initiator);
			initiator.labelText = getGangLabelText(initiator.label, initiator.color);
			target = getGangData(turfWar.target);
			target.labelText = getGangLabelText(target.label, target.color);
			remainingTime = turfWar.started ? getRemainingTime(turfWar.finishDate) : getRemainingTime(turfWar.startDate);

			const data = calculateTurfDominance(turfWar.initiatorPersonCount, turfWar.targetPersonCount);
			initiator.percentage = data.initiator;
			target.percentage = data.target;
		} else {
			initiator = null;
			target = null;
			remainingTime = null;
		}
	}

	let interval: number;
	onMount(() => {
		interval = setInterval(() => {
			if (turfWar) remainingTime = turfWar.started ? getRemainingTime(turfWar.finishDate) : getRemainingTime(turfWar.startDate);
		}, 1000);
	});

	onDestroy(() => {
		if (interval) clearTimeout(interval);
	});
</script>

{#if turfWar}
	<div class={`${$CONFIG.turfScoreboardPosition} flex items-center justify-center bg-transparent opacity-80`} transition:fade={{ duration: 100 }}>
		<div class="h-auto border-gray-400 border bg-primary rounded-sm flex flex-col p-3">
			<div class="text-gray-400 flex items-center gap-2 text-lg self-center">
				<i class="fas fa-shield fa-beat-fade" />
				{locales.dom_in_turf_war}
			</div>
			<div class="flex items-center justify-between gap-3 py-2">
				<img class="w-[2vw] h-[2vw] border-gray-700 border" src={initiator.logoURL} alt="logo" />
				<div class="flex flex-col gap-2">
					<div class="flex items-center justify-center gap-6 text-2xl">
						{@html initiator.labelText}
						{@html target.labelText}
					</div>
					{#if turfWar.started}
						<div class="flex justify-between text-black font-bold text-xl">
							<div class="px-1" style="background-color: {initiator.color}; width: {initiator.percentage - 1}%">%{initiator.percentage}</div>
							<div class="px-1 text-right" style="background-color: {target.color}; width: {target.percentage - 1}%">%{target.percentage}</div>
						</div>
					{/if}
				</div>
				<img class="w-[2vw] h-[2vw] border-gray-700 border" src={target.logoURL} alt="logo" />
			</div>
			{#if remainingTime.minute > -1}
				<div class="text-gray-400 gap-2 text-lg text-center">
					{#if turfWar.started}
						{locales.time_left_to_finish}: {locales.timer_ms.format(remainingTime.minute, remainingTime.second)}
					{:else}
						{locales.time_left_to_start}: {locales.timer_ms.format(remainingTime.minute, remainingTime.second)}
					{/if}
				</div>
			{/if}
		</div>
	</div>
{/if}
