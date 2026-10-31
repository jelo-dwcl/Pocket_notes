/// EXPERIMENT 1 switch (Part 4 of the lab).
///   false = normal app. The theme is read BEFORE runApp(), so the very first
///           frame already has the right theme and nothing flashes.
///   true  = break it on purpose. The app draws first with the light theme,
///           then reads the saved theme after a 2 second delay and flips.
///           Set it back to false after the test.
const bool kExperimentFlash = false;