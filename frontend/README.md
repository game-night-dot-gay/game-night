# game-night

## Dev Enviroment
```sh
# NPM
yay -Sy npm

# Vue CLI
npm install -g @vue/cli 

# http-server (For local prod testing)
npm install --global http-server
```

## Project Setup
```sh
npm install
```

### Compiles and hot-reloads for development
```sh
npm run serve
```

### Compiles and minifies for production
```sh
npm run build
```

### Build and serve production locally
```sh
# Requires this install
npm install --global http-server

npm run build && npx http-server dist
```

### Lints and fixes files
```sh
npm run lint
```

### Upgrade all dependencies
```sh
npx npm-check-updates -u 
npm install
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
