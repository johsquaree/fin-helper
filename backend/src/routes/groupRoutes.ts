import { Router } from 'express';
import {
  createGroup,
  getGroups,
  getGroupDetails,
  updateGroup,
  deleteGroup,
  addMemberToGroup,
  removeMemberFromGroup,
  updateMemberRole,
  joinGroupByInviteCode,
  getGroupExpenses,
} from '../controllers/groupController';
import { auth } from '../middlewares/authMiddleware';

const router = Router();

router.use(auth);

router.post('/', createGroup);
router.get('/', getGroups);
router.post('/join', joinGroupByInviteCode);
router.get('/:groupId', getGroupDetails);
router.put('/:groupId', updateGroup);
router.delete('/:groupId', deleteGroup);
router.get('/:groupId/expenses', getGroupExpenses);
router.post('/:groupId/members', addMemberToGroup);
router.delete('/:groupId/members/:memberId', removeMemberFromGroup);
router.put('/:groupId/members/:memberId/role', updateMemberRole);

export default router;
