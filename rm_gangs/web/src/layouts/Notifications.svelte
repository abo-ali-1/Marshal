<script lang="ts">
	import { NOTIFICATIONS, VISIBLE, CONFIG } from '@stores/stores';
	import { fade } from 'svelte/transition';
</script>

<div class={`z-[101] ${$VISIBLE ? $CONFIG.notificationPositionWhenInterfaceOpened : $CONFIG.notificationPosition} flex flex-col gap-1`}>
	{#each $NOTIFICATIONS as data}
		<div class="w-fit bg-primary p-3 flex items-center gap-2" transition:fade={{ duration: 300 }}>
			<i class="fa-solid fa-{data.icon}" />
			{@html data.text}
		</div>
	{/each}
</div>
