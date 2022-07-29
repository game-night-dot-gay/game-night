<template>
  <FlagLogo />
  <div class="login">
    <label>Email:</label>
    <input v-model.trim="email" @keyup.enter="requestLogin" />
    <button id="request-login-button" @click="requestLogin">Login</button>
    <div id="submission-message" :class="submissionClass">
      Check your email for the login link.
    </div>
  </div>
</template>

<style>
.login {
  padding: 1em;
}
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
      submitting: false,
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
      if (this.submitting) {
        return;
      }
      console.log(this.email);

      this.submitting = true;
      const requestLoginButton = document.getElementById(
        "request-login-button"
      );
      requestLoginButton?.setAttribute("disabled", "");
      this.submitted = true;

      fetch("/auth/request_login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: this.email }),
      }).then((r) => {
        console.log(r);
        this.submitting = false;
        requestLoginButton?.removeAttribute("disabled");
        this.email = "";
      });
    },
  },
});
</script>
