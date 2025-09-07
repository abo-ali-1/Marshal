<script lang="ts">
	import { Receive, Send } from '@enums/events';
	import { VISIBLE, CONFIG, MODAL_VISIBLE } from '@stores/stores';
	import { ReceiveEvent, SendEvent } from '@utils/eventsHandlers';
	import { onMount } from 'svelte';

	ReceiveEvent(Receive.visible, (visible: boolean): void => {
		$VISIBLE = visible;
	});

	onMount(() => {
		if (!$CONFIG.allowEscapeKey) return;

		const keyHandler = (e: KeyboardEvent) => {
			if (!$MODAL_VISIBLE && $VISIBLE && e.code === 'Escape') {
				SendEvent(Send.close);
				$VISIBLE = false;
			}
		};
		window.addEventListener('keydown', keyHandler);
		return () => window.removeEventListener('keydown', keyHandler);
	});
</script>

{#if $VISIBLE}
	<main>
		<slot />
	</main>
{/if}

<style>
	main {
		position: absolute;
		left: 0;
		top: 0;
		z-index: 100;
		user-select: none;
		box-sizing: border-box;
		padding: 0;
		margin: 0;
		height: 100vh;
		width: 100vw;
	}
</style>
