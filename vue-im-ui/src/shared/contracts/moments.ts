// Social feed (圈子 / Moments) data contracts.
import type { FlareGridImage } from "./media";

export interface FlareMomentAuthor {
  id: string;
  name: string;
  avatarUrl?: string;
}

export interface FlareMomentLike {
  id: string;
  name: string;
}

export interface FlareMomentComment {
  id: string;
  author: FlareMomentAuthor;
  text: string;
  /** When present, renders "A 回复 B". */
  replyToName?: string;
  time?: string;
}

export interface FlareMoment {
  id: string;
  author: FlareMomentAuthor;
  text?: string;
  images?: FlareGridImage[];
  /** Location line under the post. */
  location?: string;
  /** Pre-formatted time label (e.g. "2 小时前"). */
  time?: string;
  likes?: FlareMomentLike[];
  comments?: FlareMomentComment[];
  likedBySelf?: boolean;
}
