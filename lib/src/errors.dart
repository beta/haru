/// Error to throw when there are more than one commands tagged with "@entry".
class MultipleEntryCommandError extends Error {
  MultipleEntryCommandError();

  String toString() => 'There are more than one entry commands.';
}

/// Error to throw when there are more than one commands tagged with "@error".
class MultipleErrorCommandError extends Error {
  MultipleErrorCommandError();

  String toString() => 'There are more than one error commands.';
}
