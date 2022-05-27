<template>
  <div class="home">
    <object type="image/svg+xml" class="logo-image" data="/img/logo.svg">
      <img src="/img/logo.svg" />
    </object>
    <div>
      <button @click="selectFlag('gay')">Select Gay Pride Flag</button>
      <button @click="selectFlag('trans')">Select Trans Pride Flag</button>
      <button @click="selectFlag('non-binary')">
        Select Non-Binary Pride Flag
      </button>
      <button @click="selectFlag('lesbian')">Select Lesbian Pride Flag</button>
      <button @click="selectFlag('philly')">Select Philly Pride Flag</button>
      <button @click="selectFlag('agender')">Select Agender Pride Flag</button>
    </div>

    <HelloWorld msg="Welcome to Your Vue.js + TypeScript App" />
  </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";
import HelloWorld from "@/components/HelloWorld.vue"; // @ is an alias to /src

export default defineComponent({
  name: "HomeView",
  components: {
    HelloWorld,
  },
  methods: {
    selectFlag(flagClass: string) {
      // set the user's preferred flag as a cookie
      document.cookie = "flag=" + flagClass;

      // activate the flag in any "logo-image" <object> tags
      const logos = Array.from(document.getElementsByClassName("logo-image"));
      logos.forEach((logo) => {
        if (logo instanceof HTMLObjectElement) {
          const logoDocument = logo.getSVGDocument();
          const flags = logoDocument?.querySelectorAll(".flags > g");
          flags?.forEach((flag) => {
            if (flag.classList.contains(flagClass + "-flag")) {
              flag.removeAttribute("display");
            } else {
              flag.setAttribute("display", "none");
            }
          });
        } else {
          console.log(
            "Error: element with class 'logo-image' that is not a flag"
          );
        }
      });
    },
  },
});
</script>
