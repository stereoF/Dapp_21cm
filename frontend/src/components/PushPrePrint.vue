<template>
    <div class="hello">
      <button id="contractCall" @click="contractCall">get the contract owner address</button>
    </div>
  </template>
  
  <script>
    import { ethers } from "ethers";
    import PrePrintArtifact from "../contracts/PrePrintTrack.json";
    import contractAddress from "../contracts/contract-address.json";
  
    export default {
      methods: {
        contractCall: async function () {
          const provider = new ethers.providers.Web3Provider(window.ethereum);
          const prePrint = new ethers.Contract(
            contractAddress.PrePrintTrack,
            PrePrintArtifact.abi,
            provider
          );
          const ownerAddress = await prePrint.owner();
          console.log(ownerAddress.toString());
        },
      },
      name: "PushPrePrint",
      props: {

      },
      async mounted() {

      },
    };
  </script>
  
  <!-- Add "scoped" attribute to limit CSS to this component only -->
  <style scoped>
    h1 {
      margin-top: 24px;
    }
  
    h3 {
      margin: 40px 0 0;
    }
  
    ul {
      list-style-type: none;
      padding: 0;
    }
  
    li {
      display: inline-block;
      margin: 0 10px;
    }
  
    a {
      color: #42b983;
    }
  </style>
  