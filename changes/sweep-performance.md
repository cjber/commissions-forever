### Fixed

- **Bag changes no longer rescan the whole quest log.** Moving or looting an item only recounts your bags when the last quest scan is still current. The quest log is rescanned the moment it changes, when QuestieDB loads or is replaced, and when the name of a quest item the scan was waiting on arrives.
