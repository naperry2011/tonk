/**
 * LocalStorage utilities for game state persistence
 */

const STORAGE_KEYS = {
  GAME_STATE: 'tonk_game_state',
  STATISTICS: 'tonk_statistics',
  SETTINGS: 'tonk_settings'
};

/**
 * Save data to localStorage
 */
function save(key, data) {
  try {
    localStorage.setItem(key, JSON.stringify(data));
    return true;
  } catch (error) {
    console.error('Failed to save to localStorage:', error);
    return false;
  }
}

/**
 * Load data from localStorage
 */
function load(key) {
  try {
    const data = localStorage.getItem(key);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    console.error('Failed to load from localStorage:', error);
    return null;
  }
}

/**
 * Remove data from localStorage
 */
function remove(key) {
  try {
    localStorage.removeItem(key);
    return true;
  } catch (error) {
    console.error('Failed to remove from localStorage:', error);
    return false;
  }
}

/**
 * Save game state
 */
export function saveGameState(gameState) {
  return save(STORAGE_KEYS.GAME_STATE, gameState);
}

/**
 * Load game state
 */
export function loadGameState() {
  return load(STORAGE_KEYS.GAME_STATE);
}

/**
 * Clear saved game state
 */
export function clearGameState() {
  return remove(STORAGE_KEYS.GAME_STATE);
}

/**
 * Get default statistics
 */
function getDefaultStats() {
  return {
    gamesPlayed: 0,
    gamesWon: 0,
    gamesLost: 0,
    tonks: 0,
    knocks: 0,
    caughtKnocking: 0,
    totalPointsWon: 0,
    lowestWinningHand: null,
    longestWinStreak: 0,
    currentWinStreak: 0
  };
}

/**
 * Load statistics
 */
export function loadStatistics() {
  return load(STORAGE_KEYS.STATISTICS) || getDefaultStats();
}

/**
 * Save statistics
 */
export function saveStatistics(stats) {
  return save(STORAGE_KEYS.STATISTICS, stats);
}

/**
 * Update statistics after a game
 */
export function updateStatistics(won, condition, points) {
  const stats = loadStatistics();

  stats.gamesPlayed++;

  if (won) {
    stats.gamesWon++;
    stats.currentWinStreak++;
    stats.longestWinStreak = Math.max(stats.longestWinStreak, stats.currentWinStreak);
    stats.totalPointsWon += points;

    if (stats.lowestWinningHand === null || points < stats.lowestWinningHand) {
      stats.lowestWinningHand = points;
    }

    if (condition === 'tonk' || condition === 'initial-tonk') {
      stats.tonks++;
    } else if (condition === 'knock') {
      stats.knocks++;
    }
  } else {
    stats.gamesLost++;
    stats.currentWinStreak = 0;

    if (condition === 'caught') {
      stats.caughtKnocking++;
    }
  }

  saveStatistics(stats);
  return stats;
}

/**
 * Reset statistics
 */
export function resetStatistics() {
  return save(STORAGE_KEYS.STATISTICS, getDefaultStats());
}

/**
 * Get default settings
 */
function getDefaultSettings() {
  return {
    soundEnabled: true,
    animationsEnabled: true,
    difficulty: 'medium',
    defaultOpponents: 1,
    showHints: true
  };
}

/**
 * Load settings
 */
export function loadSettings() {
  return load(STORAGE_KEYS.SETTINGS) || getDefaultSettings();
}

/**
 * Save settings
 */
export function saveSettings(settings) {
  return save(STORAGE_KEYS.SETTINGS, settings);
}

/**
 * Update a single setting
 */
export function updateSetting(key, value) {
  const settings = loadSettings();
  settings[key] = value;
  return saveSettings(settings);
}

/**
 * Reset settings to defaults
 */
export function resetSettings() {
  return save(STORAGE_KEYS.SETTINGS, getDefaultSettings());
}

/**
 * Load deck theme preference
 */
export function loadDeckTheme() {
  const settings = loadSettings();
  return settings.deckTheme || 'classic';
}

/**
 * Save deck theme preference
 */
export function saveDeckTheme(theme) {
  return updateSetting('deckTheme', theme);
}

/**
 * Check if localStorage is available
 */
export function isStorageAvailable() {
  try {
    const test = '__storage_test__';
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    return false;
  }
}
