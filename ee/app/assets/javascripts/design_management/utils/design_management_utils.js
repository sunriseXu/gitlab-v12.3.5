/**
 * Returns formatted array that doesn't contain
 * `edges`->`node` nesting
 *
 * @param {Array} elements
 */

export const extractNodes = elements => elements.edges.map(({ node }) => node);

/**
 * Returns formatted array of discussions that doesn't contain
 * `edges`->`node` nesting for child notes
 *
 * @param {Array} discussions
 */

export const extractDiscussions = discussions =>
  discussions.edges.map(discussion => {
    const discussionNode = { ...discussion.node };
    discussionNode.notes = extractNodes(discussionNode.notes);
    return discussionNode;
  });

/**
 * Returns a discussion with the given id from discussions array
 *
 * @param {Array} discussions
 */

export const extractCurrentDiscussion = (discussions, id) =>
  discussions.edges.find(({ node }) => node.id === id);
