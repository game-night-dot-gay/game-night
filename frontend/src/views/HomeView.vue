<template>
  <div class="home">
    <object type="image/svg+xml" class="logo-image" data="/img/logo.svg">
      <img src="/img/logo.svg" />
    </object>
    <div>
      <button @click="selectGay">Select Gay Pride Flag</button>
      <button @click="selectTrans">Select Trans Pride Flag</button>
    </div>

    <HelloWorld msg="Welcome to Your Vue.js + TypeScript App" />
  </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";
import HelloWorld from "@/components/HelloWorld.vue"; // @ is an alias to /src

function selectFlag(flagClass: string) {
  const logos = Array.from(document.getElementsByClassName("logo-image"));
  logos.forEach((logo) => {
    if (logo instanceof HTMLObjectElement) {
      const logoDocument = logo.getSVGDocument();
      const flags = logoDocument?.querySelectorAll(".flags > g");
      flags?.forEach((flag) => {
        if (flag.classList.contains(flagClass)) {
          flag.removeAttribute("display");
        } else {
          flag.setAttribute("display", "none");
        }
      });
    } else {
      console.log("Error: element with class 'logo-image' that is not a flag");
    }
  });
}

export default defineComponent({
  name: "HomeView",
  components: {
    HelloWorld,
  },
  methods: {
    selectGay() {
      selectFlag("gay-flag");
    },
    selectTrans() {
      selectFlag("trans-flag");
    },
  },
});
</script>
