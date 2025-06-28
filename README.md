# FinalProject3

Un contrato inteligente inspirado en Uniswap que permite agregar/remover liquidez e intercambiar tokens ERC20 sin depender de ningún protocolo externo.

> Proyecto final del Módulo 3 - Formación de Builders en EthKipu

## ✨ Características

- Agregado y remoción de liquidez con cálculo proporcional.
- Swaps entre dos tokens con fee del 0.3% (Uniswap style).
- Mantenimiento automático de reservas.
- Cálculo de precios (`getAmountOut`, `_getAmountIn`).
- Protección contra reentradas (`ReentrancyGuard`).
- Uso seguro de tokens con `SafeERC20`.
- Eventos para trazabilidad on-chain.

---

## 🔧 Funcionalidades

### `addLiquidity(...)`
Permite a un proveedor agregar tokens a un par y recibir tokens de liquidez como representación de su participación.

### `removeLiquidity(...)`
Permite retirar liquidez y recibir los tokens subyacentes, en proporción al pool.

### `swapExactTokensForTokens(...)`
Realiza un swap entre dos tokens compatibles, aplicando un fee de 0.3% y asegurando un mínimo de salida (`slippage control`).

### `getReserves(...)`
Devuelve las reservas actuales del par de tokens.

### `balanceOf(...)`
Muestra el balance de tokens de liquidez del usuario para un par específico.

---

## 📘 Uso

### Despliegue

Este contrato está pensado para la red de prueba Sepolia. Puedes desplegarlo con herramientas como **Hardhat**, **Foundry** o **Remix**.

Ejemplo en Remix:
1. Cargar el contrato y compilar con Solidity ^0.8.20 o ^0.8.30.
2. Desplegar con un wallet conectado a Sepolia (ej: MetaMask).
3. Usar la interfaz para agregar liquidez y realizar swaps.

---

## ✅ Requisitos del Módulo 3 (✔️ Cumplidos)

| Requisito                                        | Cumplido |
|--------------------------------------------------|----------|
| Agregar/remover liquidez                        | ✅       |
| Swap exacto entre dos tokens                    | ✅       |
| Uso de SafeERC20                                | ✅       |
| Funciones de precio (`getAmountOut`, `_getAmountIn`) | ✅   |
| Seguridad contra reentradas                     | ✅       |
| Código limpio, legible y modular                | ✅       |
| Eventos para seguimiento                        | ✅       |

---

## 🧪 Tests y Validación

> Puedes probarlo en Remix o extenderlo con tests automatizados usando Hardhat o Foundry.

Ejemplo de prueba manual en Remix:
1. Llamar a `addLiquidity(...)` con dos tokens ERC20 desplegados.
2. Ejecutar un `swapExactTokensForTokens(...)` asegurando el `amountOutMin`.
3. Verificar reservas con `getReserves(...)`.
4. Remover liquidez y verificar balances.

---

## 📎 Referencias

- [Uniswap Whitepaper](https://uniswap.org/whitepaper-v2.pdf)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/4.x/)
- [Solidity Docs](https://docs.soliditylang.org)

---

## 🛠️ Autor

Leonel Cabral  
Builder de contratos inteligentes  
Formación EthKipu · Módulo 3 · 2025  
