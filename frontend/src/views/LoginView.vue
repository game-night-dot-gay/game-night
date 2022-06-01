<template>
  <FlagLogo />
  <div class="login">
    <label>Email:</label>
    <input v-model="email" />
    <button id="request-login-button" @click="requestLogin">Login</button>
    <div id="submission-message" :class="submissionClass">
      Check your email for the login link.
    </div>
  </div>
</template>

<style>
#submission-message {
  display: none;
}

#submission-message.display {
  display: block;
}
</style>

<script lang="ts">
import { defineComponent } from "vue";
import FlagLogo from "@/components/FlagLogo.vue"; // @ is an alias to /src

export default defineComponent({
  name: "LoginView",
  data() {
    return {
      email: "",
      submitted: false,
    };
  },
  computed: {
    submissionClass() {
      return {
        display: this.submitted,
      };
    },
  },
  components: {
    FlagLogo,
  },
  methods: {
    requestLogin() {
      console.log(this.email);

      const requestLoginButton = document.getElementById(
        "request-login-button"
      );
      requestLoginButton?.setAttribute("disabled", "");
      this.submitted = true;
    },
  },
});
</script>
