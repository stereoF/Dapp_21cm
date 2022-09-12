import { createApp } from 'vue'
import { createPinia } from 'pinia'

import Dapp from './Dapp.vue'
import router from './router'

import './assets/main.css'

const app = createApp(Dapp)

app.use(createPinia())
app.use(router)

app.mount('#app')
