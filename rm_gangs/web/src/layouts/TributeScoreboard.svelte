<script lang="ts">
	import { TRIBUTE_EVENT_DATA, CONFIG } from '@stores/stores';
	import type { Gang } from '@typings/misc';
	import { getGangData, getGangLabelText, getRemainingTime } from '@utils/misc';
	import { onDestroy, onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	import locales from '@utils/locales';

	let tributeData: { name: string; point: number; gang: Gang }[];

	$: {
		if ($TRIBUTE_EVENT_DATA)
			tributeData = Object.entries($TRIBUTE_EVENT_DATA.points)
				.map(([name, point]) => ({ name, point, gang: getGangData(name) }))
				.sort((a, b) => b.point - a.point);
	}

	let remainingTime = getRemainingTime($TRIBUTE_EVENT_DATA.finishDate);
	let interval: number;
	onMount(() => {
		interval = setInterval(() => {
			remainingTime = getRemainingTime($TRIBUTE_EVENT_DATA.finishDate);
		}, 1000);
	});

	onDestroy(() => {
		if (interval) clearTimeout(interval);
	});
</script>

{#if $TRIBUTE_EVENT_DATA}
	<div class={`${$CONFIG.tributeScoreboardPosition} flex items-center justify-center bg-transparent opacity-80`} transition:fade={{ duration: 100 }}>
		<div class="border-gray-400 border bg-primary rounded-sm flex flex-col p-3">
			<div class="text-gray-400 flex items-center gap-2 text-lg self-center">
				<i class="fas fa-shop-lock fa-beat-fade" />
				{$TRIBUTE_EVENT_DATA.zoneLabel} | {locales.points}
			</div>
			<div class="flex flex-col gap-3 py-2">
				{#each tributeData as data}
					<div class="flex gap-6 items-center">
						<img class="w-[2vw] h-[2vw] border-gray-700 border" src={data.gang.logoURL} alt="logo" />
						{@html getGangLabelText(data.gang.label, data.gang.color)}
						<div class="font-bold ml-auto">{data.point}</div>
					</div>
				{/each}
			</div>
			{#if remainingTime.minute > -1}
				<div class="text-gray-400 gap-2 text-lg text-center">
					{locales.time_left_to_finish}: {locales.timer_ms.format(remainingTime.minute, remainingTime.second)}
				</div>
			{/if}
		</div>
	</div>
{/if}
