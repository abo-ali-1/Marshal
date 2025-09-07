<script lang="ts">
	import { WAR_FEED, CONFIG } from '@stores/stores';
	import { fade } from 'svelte/transition';
</script>

<div class={`${$CONFIG.warFeedPosition} flex flex-col items-end gap-1`}>
	{#each $WAR_FEED as data}
		<div class="w-fit bg-primary p-3 flex items-center gap-2" transition:fade={{ duration: 300 }}>
			{#if data.started}
				<i class="fa-solid fa-flag-checkered text-gray-500 fa-bounce" />
			{/if}
			{#if data.finished}
				{#if data.highlightedSide == 'initiator'}
					<i class="fa-solid fa-crown text-gray-500 fa-bounce" />
				{:else}
					<i class="fa-solid fa-face-sad-cry text-gray-500" />
				{/if}
			{/if}
			<img class="w-[1vw] h-[1vw] border-gray-700 border" src={data.initiatorLogoURL} alt="logo" />
			{@html data.initiatorLabelText}
			<div class="text-gray-400 {data.highlightedSide == 'initiator' ? ' fa-beat' : ''}">{data.initiatorScore}</div>
			:
			<div class="text-gray-400 {data.highlightedSide == 'target' ? 'fa-beat' : ''}">{data.targetScore}</div>
			{@html data.targetLabelText}
			<img class="w-[1vw] h-[1vw] border-gray-700 border" src={data.targetLogoURL} alt="logo" />
			{#if data.finished}
				{#if data.highlightedSide == 'target'}
					<i class="fa-solid fa-crown text-gray-500 fa-bounce" />
				{:else}
					<i class="fa-solid fa-face-sad-cry text-gray-500" />
				{/if}
			{/if}
		</div>
	{/each}
</div>
