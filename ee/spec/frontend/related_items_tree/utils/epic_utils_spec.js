import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import { ChildType, PathIdSeparator } from 'ee/related_items_tree/constants';

import {
  mockQueryResponse,
  mockEpic1,
  mockIssue1,
} from '../../../javascripts/related_items_tree/mock_data';

jest.mock('~/lib/graphql', () => jest.fn());

describe('RelatedItemsTree', () => {
  describe('epicUtils', () => {
    describe('formatChildItem', () => {
      it('returns new object from provided item object with pathIdSeparator assigned', () => {
        const item = {
          type: ChildType.Epic,
        };

        expect(epicUtils.formatChildItem(item)).toHaveProperty('type', ChildType.Epic);
        expect(epicUtils.formatChildItem(item)).toHaveProperty(
          'pathIdSeparator',
          PathIdSeparator.Epic,
        );
      });
    });

    describe('extractChildEpics', () => {
      it('returns updated epics array with `type` and `pathIdSeparator` assigned and `edges->node` nesting removed', () => {
        const formattedChildren = epicUtils.extractChildEpics(
          mockQueryResponse.data.group.epic.children,
        );

        expect(formattedChildren.length).toBe(
          mockQueryResponse.data.group.epic.children.edges.length,
        );
        expect(formattedChildren[0]).toHaveProperty('type', ChildType.Epic);
        expect(formattedChildren[0]).toHaveProperty('pathIdSeparator', PathIdSeparator.Epic);
        expect(formattedChildren[0]).toHaveProperty('fullPath', mockEpic1.group.fullPath);
      });
    });

    describe('extractIssueAssignees', () => {
      it('returns updated assignees array with `edges->node` nesting removed', () => {
        const formattedChildren = epicUtils.extractIssueAssignees(mockIssue1.assignees);

        expect(formattedChildren.length).toBe(mockIssue1.assignees.edges.length);
        expect(formattedChildren[0]).toHaveProperty(
          'username',
          mockIssue1.assignees.edges[0].node.username,
        );
      });
    });

    describe('extractChildIssues', () => {
      it('returns updated issues array with `type` and `pathIdSeparator` assigned and `edges->node` nesting removed', () => {
        const formattedChildren = epicUtils.extractChildIssues(
          mockQueryResponse.data.group.epic.issues,
        );

        expect(formattedChildren.length).toBe(
          mockQueryResponse.data.group.epic.issues.edges.length,
        );
        expect(formattedChildren[0]).toHaveProperty('type', ChildType.Issue);
        expect(formattedChildren[0]).toHaveProperty('pathIdSeparator', PathIdSeparator.Issue);
      });
    });

    describe('processQueryResponse', () => {
      it('returns array of issues and epics from query response with issues being on top of the list', () => {
        const formattedChildren = epicUtils.processQueryResponse(mockQueryResponse.data.group);

        expect(formattedChildren.length).toBe(4); // 2 Epics and 2 Issues
        expect(formattedChildren[0]).toHaveProperty('type', ChildType.Epic);
        expect(formattedChildren[1]).toHaveProperty('type', ChildType.Epic);
        expect(formattedChildren[2]).toHaveProperty('type', ChildType.Issue);
        expect(formattedChildren[3]).toHaveProperty('type', ChildType.Issue);
      });
    });
  });
});
