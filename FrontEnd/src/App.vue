<script setup>
import { RouterView } from 'vue-router'
import Navbar from './components/layout/Navbar.vue' 
</script>

<template>
  <div id="app">
   
    <Navbar />
    
    <main>
      <RouterView />
    </main>
  </div>
</template>

<style>

* { 
  margin: 0; 
  padding: 0; 
  box-sizing: border-box; 
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background-color: #f8f9fa;
  color: #2c3e50;
}

main {
  padding-top: 0; 
  min-height: 0;
}
</style>