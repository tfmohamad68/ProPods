import { ObjectRecordsPermissions } from 'twenty-shared/types';
import { ObjectLiteral, SelectQueryBuilder } from 'typeorm';
import { QueryDeepPartialEntity } from 'typeorm/query-builder/QueryPartialEntity';

import { WorkspaceInternalContext } from 'src/engine/twenty-orm/interfaces/workspace-internal-context.interface';

import {
  PermissionsException,
  PermissionsExceptionCode,
} from 'src/engine/metadata-modules/permissions/permissions.exception';
import { validateQueryIsPermittedOrThrow } from 'src/engine/twenty-orm/repository/permissions.utils';
import { WorkspaceDeleteQueryBuilder } from 'src/engine/twenty-orm/repository/workspace-delete-query-builder';
import { WorkspaceInsertQueryBuilder } from 'src/engine/twenty-orm/repository/workspace-insert-query-builder';
import { WorkspaceSoftDeleteQueryBuilder } from 'src/engine/twenty-orm/repository/workspace-soft-delete-query-builder';
import { WorkspaceUpdateQueryBuilder } from 'src/engine/twenty-orm/repository/workspace-update-query-builder';

export class WorkspaceSelectQueryBuilder<
  T extends ObjectLiteral,
> extends SelectQueryBuilder<T> {
  objectRecordsPermissions: ObjectRecordsPermissions;
  shouldBypassPermissionChecks: boolean;
  internalContext: WorkspaceInternalContext;
  constructor(
    queryBuilder: SelectQueryBuilder<T>,
    objectRecordsPermissions: ObjectRecordsPermissions,
    internalContext: WorkspaceInternalContext,
    shouldBypassPermissionChecks: boolean,
  ) {
    super(queryBuilder);
    this.objectRecordsPermissions = objectRecordsPermissions;
    this.internalContext = internalContext;
    this.shouldBypassPermissionChecks = shouldBypassPermissionChecks;
  }

  override clone(): this {
    const clonedQueryBuilder = super.clone();

    return new WorkspaceSelectQueryBuilder(
      clonedQueryBuilder,
      this.objectRecordsPermissions,
      this.internalContext,
      this.shouldBypassPermissionChecks,
    ) as this;
  }

  override execute(): Promise<T[]> {
    this.validatePermissions();

    return super.execute();
  }

  override getMany(): Promise<T[]> {
    this.validatePermissions();

    return super.getMany();
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  override getRawOne<U = any>(): Promise<U | undefined> {
    this.validatePermissions();

    return super.getRawOne();
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  override getRawMany<U = any>(): Promise<U[]> {
    this.validatePermissions();

    return super.getRawMany();
  }

  override getOne(): Promise<T | null> {
    this.validatePermissions();

    return super.getOne();
  }

  override getOneOrFail(): Promise<T> {
    this.validatePermissions();

    return super.getOneOrFail();
  }

  override getCount(): Promise<number> {
    this.validatePermissions();

    return super.getCount();
  }

  override getExists(): Promise<boolean> {
    throw new PermissionsException(
      'getExists is not supported because it calls dataSource.createQueryBuilder()',
      PermissionsExceptionCode.METHOD_NOT_ALLOWED,
    );
  }

  override getManyAndCount(): Promise<[T[], number]> {
    this.validatePermissions();

    return super.getManyAndCount();
  }

  override insert(): WorkspaceInsertQueryBuilder<T> {
    const insertQueryBuilder = super.insert();

    return new WorkspaceInsertQueryBuilder<T>(
      insertQueryBuilder,
      this.objectRecordsPermissions,
      this.internalContext,
      this.shouldBypassPermissionChecks,
    );
  }

  override update(): WorkspaceUpdateQueryBuilder<T>;

  override update(
    updateSet: QueryDeepPartialEntity<T>,
  ): WorkspaceUpdateQueryBuilder<T>;

  override update(
    updateSet?: QueryDeepPartialEntity<T>,
  ): WorkspaceUpdateQueryBuilder<T> {
    const updateQueryBuilder = updateSet
      ? super.update(updateSet)
      : super.update();

    return new WorkspaceUpdateQueryBuilder<T>(
      updateQueryBuilder,
      this.objectRecordsPermissions,
      this.internalContext,
      this.shouldBypassPermissionChecks,
    );
  }

  override delete(): WorkspaceDeleteQueryBuilder<T> {
    const deleteQueryBuilder = super.delete();

    return new WorkspaceDeleteQueryBuilder<T>(
      deleteQueryBuilder,
      this.objectRecordsPermissions,
      this.internalContext,
      this.shouldBypassPermissionChecks,
    );
  }

  override softDelete(): WorkspaceSoftDeleteQueryBuilder<T> {
    const softDeleteQueryBuilder = super.softDelete();

    return new WorkspaceSoftDeleteQueryBuilder<T>(
      softDeleteQueryBuilder,
      this.objectRecordsPermissions,
      this.internalContext,
      this.shouldBypassPermissionChecks,
    );
  }

  override restore(): WorkspaceSoftDeleteQueryBuilder<T> {
    const restoreQueryBuilder = super.restore();

    return new WorkspaceSoftDeleteQueryBuilder<T>(
      restoreQueryBuilder,
      this.objectRecordsPermissions,
      this.internalContext,
      this.shouldBypassPermissionChecks,
    );
  }

  override executeExistsQuery(): Promise<boolean> {
    throw new PermissionsException(
      'executeExistsQuery is not supported because it calls dataSource.createQueryBuilder()',
      PermissionsExceptionCode.METHOD_NOT_ALLOWED,
    );
  }

  private validatePermissions(): void {
    validateQueryIsPermittedOrThrow(
      this.expressionMap,
      this.objectRecordsPermissions,
      this.internalContext.objectMetadataMaps,
      this.shouldBypassPermissionChecks,
    );
  }
}
