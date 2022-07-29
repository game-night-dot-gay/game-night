<template>
  <div class="home">
    <FlagLogo />
  </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";
import FlagLogo from "@/components/FlagLogo.vue"; // @ is an alias to /src

export default defineComponent({
  name: "HomeView",
  components: {
    FlagLogo,
  },
});
</script>
