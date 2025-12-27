/**
 * Animation utilities for card movements
 */

/**
 * Delay helper
 */
export function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Animate a card dealing from deck
 */
export async function animateCardDeal(cardElement, targetRect, delayMs = 0) {
  if (delayMs > 0) {
    await delay(delayMs);
  }

  cardElement.classList.add('dealing');
  await delay(300);
  cardElement.classList.remove('dealing');
}

/**
 * Animate card flip
 */
export async function animateCardFlip(cardElement) {
  cardElement.classList.add('flipping');
  await delay(400);
  cardElement.classList.remove('flipping');
}

/**
 * Animate card movement from one position to another
 */
export async function animateCardMove(cardElement, fromRect, toRect, duration = 300) {
  const startX = fromRect.left;
  const startY = fromRect.top;
  const endX = toRect.left;
  const endY = toRect.top;

  cardElement.style.position = 'fixed';
  cardElement.style.left = `${startX}px`;
  cardElement.style.top = `${startY}px`;
  cardElement.style.transition = `all ${duration}ms ease-out`;
  cardElement.style.zIndex = '1000';

  // Force reflow
  cardElement.offsetHeight;

  cardElement.style.left = `${endX}px`;
  cardElement.style.top = `${endY}px`;

  await delay(duration);

  // Reset styles
  cardElement.style.position = '';
  cardElement.style.left = '';
  cardElement.style.top = '';
  cardElement.style.transition = '';
  cardElement.style.zIndex = '';
}

/**
 * Animate shake (for invalid actions)
 */
export function animateShake(element) {
  element.style.animation = 'shake 0.5s ease-in-out';
  element.addEventListener('animationend', () => {
    element.style.animation = '';
  }, { once: true });
}

/**
 * Animate pulse (for highlighting)
 */
export function animatePulse(element, duration = 1000) {
  element.style.animation = `pulse ${duration}ms ease-in-out`;
  return new Promise(resolve => {
    element.addEventListener('animationend', () => {
      element.style.animation = '';
      resolve();
    }, { once: true });
  });
}

/**
 * Fade in animation
 */
export async function fadeIn(element, duration = 300) {
  element.style.opacity = '0';
  element.style.transition = `opacity ${duration}ms ease-in`;

  // Force reflow
  element.offsetHeight;

  element.style.opacity = '1';

  await delay(duration);
  element.style.transition = '';
}

/**
 * Fade out animation
 */
export async function fadeOut(element, duration = 300) {
  element.style.transition = `opacity ${duration}ms ease-out`;
  element.style.opacity = '0';

  await delay(duration);
  element.style.transition = '';
}

/**
 * Staggered animation for multiple elements
 */
export async function staggerAnimation(elements, animationFn, staggerDelay = 100) {
  const promises = [];

  for (let i = 0; i < elements.length; i++) {
    promises.push(
      delay(i * staggerDelay).then(() => animationFn(elements[i]))
    );
  }

  await Promise.all(promises);
}

// Add keyframes for shake animation if not present
const style = document.createElement('style');
style.textContent = `
  @keyframes shake {
    0%, 100% { transform: translateX(0); }
    10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
    20%, 40%, 60%, 80% { transform: translateX(5px); }
  }
`;
document.head.appendChild(style);
