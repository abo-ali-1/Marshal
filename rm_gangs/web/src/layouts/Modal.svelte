<script lang="ts">
	import { MODAL_VISIBLE } from '@stores/stores';
	import { onMount } from 'svelte';
	import { fade } from 'svelte/transition';
	export let show: boolean;

	$: $MODAL_VISIBLE = show;

	onMount(() => {
		const keyHandler = (e: KeyboardEvent) => {
			if (e.code === 'Escape') {
				show = false;
			}
		};
		window.addEventListener('keydown', keyHandler);
		return () => window.removeEventListener('keydown', keyHandler);
	});
</script>

{#if show}
	<!-- svelte-ignore a11y-click-events-have-key-events -->
	<!-- svelte-ignore a11y-no-static-element-interactions -->
	<div id="modal" class="fixed top-0 left-0 bottom-0 right-0 flex items-center justify-center bg-black bg-opacity-75 z-[401]" transition:fade={{ duration: 100 }}>
		<!-- svelte-ignore a11y-click-events-have-key-events -->
		<!-- svelte-ignore a11y-no-static-element-interactions -->
		<div class=" border-gray-400 border-2 bg-primary rounded-sm flex flex-col p-3" on:click|stopPropagation>
			<i class="w-full text-right text-gray-400 ps-[0.5vw] cursor-pointer fas fa-xmark text-[2vh]" on:click={() => (show = false)} />
			<slot />
		</div>
	</div>
{/if}
